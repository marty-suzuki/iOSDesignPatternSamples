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

    let viewModel: SearchViewModelType
    let dataSource: SearchViewDataSource

    private let makeRepositoryViewModel: (Repository) -> RepositoryViewModelType
    private let makeUserRepositoryViewModel: (User) -> UserRepositoryViewModelType
    private var cancellables = Set<AnyCancellable>()

    init(
        viewModel: SearchViewModelType,
        makeUserRepositoryViewModel: @escaping (User) -> UserRepositoryViewModelType,
        makeRepositoryViewModel: @escaping (Repository) -> RepositoryViewModelType
    ) {
        self.makeRepositoryViewModel = makeRepositoryViewModel
        self.makeUserRepositoryViewModel = makeUserRepositoryViewModel
        self.viewModel = viewModel
        self.dataSource = SearchViewDataSource(viewModel: viewModel)
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

        // observe viewModel
        viewModel.output.accessTokenAlert
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: showAccessTokenAlert)
            .store(in: &cancellables)

        viewModel.output.keyboardWillShow
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: keyboardWillShow)
            .store(in: &cancellables)

        viewModel.output.keyboardWillHide
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: keyboardWillHide)
            .store(in: &cancellables)

        viewModel.output.countString
            .map(Optional.some)
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: totalCountLabel)
            .store(in: &cancellables)

        viewModel.output.reloadData
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reloadData)
            .store(in: &cancellables)

        viewModel.output.selectedUser
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: showUserRepository)
            .store(in: &cancellables)

        viewModel.output.updateLoadingView
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: updateLoadingView)
            .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.input.viewDidAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.input.viewDidDisappear()
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

    private var showUserRepository: (User) -> Void {
        { [weak self] user in
            guard let me = self else {
                return
            }
            let vm = me.makeUserRepositoryViewModel(user)
            let vc = UserRepositoryViewController(
                viewModel: vm,
                makeRepositoryViewModel: me.makeRepositoryViewModel
            )
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
        viewModel.input.searchText(searchBar.text)
    }
}
