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

    private var cancelllables = Set<AnyCancellable>()
    private var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                searchModel.fetchUsers()
            }
        }
    }
    
    let favoriteModel: FavoriteModelType
    let searchModel: SearchModelType
    private let makeRepositoryModel: (User) -> RepositoryModelType

    init(
        searchModel: SearchModelType,
        favoriteModel: FavoriteModelType,
        makeRepositoryModel: @escaping (User) -> RepositoryModelType
    ) {
        self.searchModel = searchModel
        self.favoriteModel = favoriteModel
        self.makeRepositoryModel = makeRepositoryModel
        super.init(nibName: SearchViewController.className, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = searchBar
        searchBar.delegate = self
        searchBar.placeholder = "Input user name"
        
        configure(with: tableView)

        searchModel.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeKeyboard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
        cancelllables.removeAll()
    }
    
    private func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UserViewCell.self)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.className)
    }
    
    private func observeKeyboard() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                guard let info = UIKeyboardInfo(notification: notification) else {
                    return
                }
                self?.view.layoutIfNeeded()
                let extra = self?.tabBarController?.tabBar.bounds.height ?? 0
                self?.tableViewBottomConstraint.constant = info.frame.size.height - extra
                UIView.animate(withDuration: info.animationDuration, delay: 0, options: info.animationCurve, animations: {
                    self?.view.layoutIfNeeded()
                }, completion: nil)
            }
            .store(in: &cancelllables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                guard let info = UIKeyboardInfo(notification: notification) else {
                    return
                }
                self?.view.layoutIfNeeded()
                self?.tableViewBottomConstraint.constant = 0
                UIView.animate(withDuration: info.animationDuration, delay: 0, options: info.animationCurve, animations: {
                    self?.view.layoutIfNeeded()
                }, completion: nil)
            }
            .store(in: &cancelllables)
    }
    
    private func showUserRepository(with user: User) {
        let repositoryModel = makeRepositoryModel(user)
        let vc = UserRepositoryViewController(repositoryModel: repositoryModel, favoriteModel: favoriteModel)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension SearchViewController: SearchModelDelegate {
    func searchModel(_ searchModel: SearchModel, didRecieve errorMessage: ErrorMessage) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: errorMessage.title,
                                          message: errorMessage.message,
                                          preferredStyle: .alert)
            self.present(alert, animated: false, completion: nil)
        }
    }

    func searchModel(_ searchModel: SearchModel, didChange isFetchingUsers: Bool) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func searchModel(_ searchModel: SearchModel, didChange users: [User]) {
        let totalCount = searchModel.totalCount
        DispatchQueue.main.async {
            self.totalCountLabel.text = "\(users.count) / \(totalCount)"
            self.tableView.reloadData()
        }
    }

    func searchModel(_ searchModel: SearchModel, didChange totalCount: Int) {
        let users = searchModel.users
        DispatchQueue.main.async {
            self.totalCountLabel.text = "\(users.count) / \(totalCount)"
        }
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
        searchModel.fetchUsers(withQuery: searchText)
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchModel.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UserViewCell.self, for: indexPath)
        cell.configure(with: searchModel.users[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: UITableViewHeaderFooterView.className) else {
            return nil
        }
        loadingView.removeFromSuperview()
        loadingView.isLoading = searchModel.isFetchingUsers
        loadingView.add(to: view)
        return view
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let user = searchModel.users[indexPath.row]
        showUserRepository(with: user)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UserViewCell.calculateHeight(with: searchModel.users[indexPath.row], and: tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return searchModel.isFetchingUsers ? LoadingView.defaultHeight : .leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
        isReachedBottom = maxScrollDistance <= scrollView.contentOffset.y
    }
}
