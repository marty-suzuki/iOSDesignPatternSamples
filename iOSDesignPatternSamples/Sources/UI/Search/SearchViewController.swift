//
//  SearchViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

protocol SearchView: class {
    func reloadData()
    func keyboardWillShow(with keyboardInfo: UIKeyboardInfo)
    func keyboardWillHide(with keyboardInfo: UIKeyboardInfo)
    func showUserRepository(with user: User)
    func updateTotalCountLabel(_ countText: String)
    func updateLoadingView(with view: UIView, isLoading: Bool)
    func showEmptyTokenError()
}

final class SearchViewController: UIViewController, SearchView {
    @IBOutlet weak var totalCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    private(set) lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = self
        return searchBar
    }()
    
<<<<<<< HEAD
    fileprivate let loadingView = LoadingView.makeFromNib()
    
    var favoritePresenter: FavoritePresenter?
=======
    private var query: String = "" {
        didSet {
            if query != oldValue {
                users.removeAll()
                pageInfo = nil
                totalCount = 0
            }
            task?.cancel()
            task = nil
            fetchUsers()
        }
    }
    private var task: URLSessionTask? = nil
    private var pageInfo: PageInfo? = nil
    private var totalCount: Int = 0 {
        didSet {
            totalCountLabel.text = "\(users.count) / \(totalCount)"
        }
    }
    private var users: [User] = [] {
        didSet {
            totalCountLabel.text = "\(users.count) / \(totalCount)"
            tableView.reloadData()
        }
    }
    private let debounce: (_ action: @escaping () -> ()) -> () = {
        var lastFireTime: DispatchTime = .now()
        let delay: DispatchTimeInterval = .milliseconds(500)
        return { [delay] action in
            let deadline: DispatchTime = .now() + delay
            lastFireTime = .now()
            DispatchQueue.global().asyncAfter(deadline: deadline) { [delay] in
                let now: DispatchTime = .now()
                let when: DispatchTime = lastFireTime + delay
                if now < when { return }
                lastFireTime = .now()
                DispatchQueue.main.async {
                    action()
                }
            }
        }
    }()
    private var isFetchingUsers = false {
        didSet {
            tableView.reloadData()
        }
    }
    private var pool = Notice.ObserverPool()
    
    private let loadingView = LoadingView.makeFromNib()
    
    private var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                fetchUsers()
            }
        }
    }
>>>>>>> mvc
    
    private lazy var presenter: SearchPresenter = SearchViewPresenter(view: self)
    private lazy var dataSource: SearchViewDataSource = .init(presenter: self.presenter)

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = searchBar
        searchBar.placeholder = "Input user name"
        
        dataSource.configure(with: tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
<<<<<<< HEAD
        presenter.viewWillDisappear()
=======
        pool = Notice.ObserverPool()
>>>>>>> mvc
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
<<<<<<< HEAD
    func keyboardWillShow(with keyboardInfo: UIKeyboardInfo) {
        view.layoutIfNeeded()
        let extra = tabBarController?.tabBar.bounds.height ?? 0
        tableViewBottomConstraint.constant = keyboardInfo.frame.size.height - extra
        UIView.animate(withDuration: keyboardInfo.animationDuration,
                       delay: 0,
                       options: keyboardInfo.animationCurve,
                       animations: { self.view.layoutIfNeeded() },
                       completion: nil)
=======
    private func observeKeyboard() {
        NotificationCenter.default.nok.observe(name: .keyboardWillShow) { [weak self] in
            self?.view.layoutIfNeeded()
            let extra = self?.tabBarController?.tabBar.bounds.height ?? 0
            self?.tableViewBottomConstraint.constant = $0.frame.size.height - extra
            UIView.animate(withDuration: $0.animationDuration, delay: 0, options: $0.animationCurve, animations: {
                self?.view.layoutIfNeeded()
            }, completion: nil)
        }
        .invalidated(by: pool)

        NotificationCenter.default.nok.observe(name: .keyboardWillHide) { [weak self] in
            self?.view.layoutIfNeeded()
            self?.tableViewBottomConstraint.constant = 0
            UIView.animate(withDuration: $0.animationDuration, delay: 0, options: $0.animationCurve, animations: {
                self?.view.layoutIfNeeded()
            }, completion: nil)
        }
        .invalidated(by: pool)
>>>>>>> mvc
    }
    
    func keyboardWillHide(with keyboardInfo: UIKeyboardInfo) {
        view.layoutIfNeeded()
        tableViewBottomConstraint.constant = 0
        UIView.animate(withDuration: keyboardInfo.animationDuration,
                       delay: 0,
                       options: keyboardInfo.animationCurve,
                       animations: { self.view.layoutIfNeeded() },
                       completion: nil)
    }
    
<<<<<<< HEAD
    func showUserRepository(with user: User) {
        guard let presenter = favoritePresenter else { return }
        let vc = UserRepositoryViewController(user: user, favoritePresenter: presenter)
=======
    private func showUserRepository(with user: User) {
        guard let favoriteModel = favoriteModel else { return }
        let vc = UserRepositoryViewController(user: user, favoriteModel: favoriteModel)
>>>>>>> mvc
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func updateTotalCountLabel(_ countText: String) {
        totalCountLabel.text = countText
    }
    
    func updateLoadingView(with view: UIView, isLoading: Bool) {
        loadingView.removeFromSuperview()
        loadingView.isLoading = isLoading
        loadingView.add(to: view)
    }

    func showEmptyTokenError() {
        let alert = UIAlertController(title: "Access Token Error",
                                      message: "\"Github Personal Access Token\" is Required.\n Please set it in ApiSession.extension.swift!",
                                      preferredStyle: .alert)
        present(alert, animated: false, completion: nil)
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter.search(queryIfNeeded: searchText)
    }
}
