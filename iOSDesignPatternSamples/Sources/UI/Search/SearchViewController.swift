//
//  SearchViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit
import UIKit

final class SearchViewController: UIViewController {

    @IBOutlet private(set) weak var totalCountLabel: UILabel!
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var tableViewBottomConstraint: NSLayoutConstraint!

    let searchBar = UISearchBar(frame: .zero)
    let loadingView = LoadingView()

    private let flux: Flux
    let dataSource: SearchViewDataSource

    @Published
    private var query = ""
    private let _searchText = PassthroughSubject<String?, Never>()
    private let _viewDidAppear = PassthroughSubject<Void, Never>()
    private let _viewDidDisappear = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(flux: Flux) {
        self.flux = flux
        self.dataSource = SearchViewDataSource(flux: flux)
        super.init(nibName: SearchViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = searchBar
        searchBar.placeholder = "Input user name"
        searchBar.delegate = self
        dataSource.configure(with: tableView)

        // observe store
        let store = flux.userStore
        let action = flux.userAction
        let users = store.$users
        let totalCount = store.$userTotalCount
        let isFetching = store.$isUserFetching

        store.$selectedUser
            .filter { $0 != nil }
            .map { _ in }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: showUserRepository)
            .store(in: &cancellables)

        users.map { _ in }
            .merge(with: totalCount.map { _ in }, isFetching.map { _ in })
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reloadData)
            .store(in: &cancellables)

        dataSource.headerFooterView
            .combineLatest(isFetching)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: updateLoadingView)
            .store(in: &cancellables)

        totalCount
            .zip(users) { "\($1.count) / \($0)" }
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: totalCountLabel)
            .store(in: &cancellables)

        // keyboard notification
        let isViewAppearing = _viewDidAppear.map { true }
            .merge(with: _viewDidDisappear.map { false })

        isViewAppearing
            .map { isViewAppearing -> AnyPublisher<UIKeyboardInfo, Never> in
                guard isViewAppearing else {
                    return Empty().eraseToAnyPublisher()
                }
                return NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                    .flatMap { notification -> AnyPublisher<UIKeyboardInfo, Never> in
                        guard let info = UIKeyboardInfo(notification: notification) else {
                            return Empty().eraseToAnyPublisher()
                        }
                        return Just(info).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink(receiveValue: keyboardWillShow)
            .store(in: &cancellables)

        isViewAppearing
            .map { isViewAppearing -> AnyPublisher<UIKeyboardInfo, Never> in
                guard isViewAppearing else {
                    return Empty().eraseToAnyPublisher()
                }
                return NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                    .flatMap { notification -> AnyPublisher<UIKeyboardInfo, Never> in
                        guard let info = UIKeyboardInfo(notification: notification) else {
                            return Empty().eraseToAnyPublisher()
                        }
                        return Just(info).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink(receiveValue: keyboardWillHide)
            .store(in: &cancellables)

        // search
        _searchText
            .map { $0 ?? "" }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.query, on: self)
            .store(in: &cancellables)

        let endCousor = store.$lastPageInfo
            .map { $0?.endCursor }

        let initialLoad = $query
            .filter { !$0.isEmpty }
            .flatMap { query in
                endCousor
                    .map { (query, $0) }
                    .prefix(1)
            }

        let loadMore = dataSource.isReachedBottom
            .filter { $0 }
            .flatMap { [weak self] _ -> AnyPublisher<(String, String?), Never> in
                guard let me = self else {
                    return Empty().eraseToAnyPublisher()
                }
                return me.$query
                    .combineLatest(endCousor)
                    .eraseToAnyPublisher()
            }
            .filter { !$0.isEmpty && $1 != nil }

        $query
            .sink { _ in
                action.clearPageInfo()
                action.removeAllUsers()
                action.userTotalCount(0)
            }
            .store(in: &cancellables)

        initialLoad
            .merge(with: loadMore)
            .map { SearchUserRequest(query: $0, after: $1) }
            .removeDuplicates { $0.query == $1.query && $0.after == $1.after }
            .sink { request in
                //action.fetchUsers(withQuery: request.query, after: request.after)
            }
            .store(in: &cancellables)

        isViewAppearing
            .map { isAppearing -> AnyPublisher<ErrorMessage, Never> in
                guard isAppearing else {
                    return Empty().eraseToAnyPublisher()
                }
                return store.fetchError
            }
            .switchToLatest()
            .sink(receiveValue: showAccessTokenAlert)
            .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _viewDidAppear.send()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _viewDidDisappear.send()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.resignFirstResponder()
    }

    private var showAccessTokenAlert: (ErrorMessage) -> Void {
        { [weak self] error in
            guard let me = self else {
                return
            }
            let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
            me.present(alert, animated: false, completion: nil)
        }
    }

    private var reloadData: () -> Void  {
        { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private var keyboardWillShow: (UIKeyboardInfo) -> Void {
        { [weak self] keyboardInfo in
            guard let me = self else {
                return
            }
            me.view.layoutIfNeeded()
            let extra = me.tabBarController?.tabBar.bounds.height ?? 0
            me.tableViewBottomConstraint.constant = keyboardInfo.frame.size.height - extra
            UIView.animate(withDuration: keyboardInfo.animationDuration,
                           delay: 0,
                           options: keyboardInfo.animationCurve,
                           animations: { me.view.layoutIfNeeded() },
                           completion: nil)
        }
    }

    private var keyboardWillHide: (UIKeyboardInfo) -> Void {
        { [weak self] keyboardInfo in
            guard let me = self else {
                return
            }
            me.view.layoutIfNeeded()
            me.tableViewBottomConstraint.constant = 0
            UIView.animate(withDuration: keyboardInfo.animationDuration,
                           delay: 0,
                           options: keyboardInfo.animationCurve,
                           animations: { me.view.layoutIfNeeded() },
                           completion: nil)
        }
    }

    private var showUserRepository: () -> Void {
        { [weak self] in
            guard let me = self else {
                return
            }
            let vc = UserRepositoryViewController(flux: me.flux)
            me.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private var updateLoadingView: (UIView, Bool) -> Void {
        { [weak self] view, isLoading in
            guard let me = self else {
                return
            }
            me.loadingView.removeFromSuperview()
            me.loadingView.isLoading = isLoading
            me.loadingView.add(to: view)
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        _searchText.send(searchBar.text)
    }
}
