//
//  SearchViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

<<<<<<< HEAD
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

    fileprivate let loadingView = LoadingView.makeFromNib()

    var favoritePresenter: FavoritePresenter?

    private lazy var presenter: SearchPresenter = SearchViewPresenter(view: self)
    private lazy var dataSource: SearchViewDataSource = .init(presenter: self.presenter)
=======
final class SearchViewController: UIViewController {
    
    @IBOutlet private(set) weak var totalCountLabel: UILabel!
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var tableViewBottomConstraint: NSLayoutConstraint!

    let searchBar = UISearchBar(frame: .zero)
    let loadingView = LoadingView.makeFromNib()

    private var pool = Notice.ObserverPool()
    private var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                searchModel.fetchUsers()
            }
        }
    }
    
    let favoriteModel: FavoriteModel
    let searchModel: SearchModel

    init(searchModel: SearchModel, favoriteModel: FavoriteModel) {
        self.searchModel = searchModel
        self.favoriteModel = favoriteModel
        super.init(nibName: SearchViewController.className, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
>>>>>>> mvc

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = searchBar
        searchBar.delegate = self
        searchBar.placeholder = "Input user name"
<<<<<<< HEAD

        dataSource.configure(with: tableView)
=======
        
        configure(with: tableView)

        searchModel.delegate = self
>>>>>>> mvc
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
        presenter.viewWillDisappear()
    }

    func reloadData() {
        tableView.reloadData()
    }

    func keyboardWillShow(with keyboardInfo: UIKeyboardInfo) {
        view.layoutIfNeeded()
        let extra = tabBarController?.tabBar.bounds.height ?? 0
        tableViewBottomConstraint.constant = keyboardInfo.frame.size.height - extra
        UIView.animate(withDuration: keyboardInfo.animationDuration,
                       delay: 0,
                       options: keyboardInfo.animationCurve,
                       animations: { self.view.layoutIfNeeded() },
                       completion: nil)
    }
<<<<<<< HEAD

    func keyboardWillHide(with keyboardInfo: UIKeyboardInfo) {
        view.layoutIfNeeded()
        tableViewBottomConstraint.constant = 0
        UIView.animate(withDuration: keyboardInfo.animationDuration,
                       delay: 0,
                       options: keyboardInfo.animationCurve,
                       animations: { self.view.layoutIfNeeded() },
                       completion: nil)
    }

    func showUserRepository(with user: User) {
        guard let presenter = favoritePresenter else { return }
        let vc = UserRepositoryViewController(user: user, favoritePresenter: presenter)
=======
    
    private func showUserRepository(with user: User) {
        let repositoryModel = RepositoryModel(user: user)
        let vc = UserRepositoryViewController(repositoryModel: repositoryModel, favoriteModel: favoriteModel)
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
<<<<<<< HEAD

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter.search(queryIfNeeded: searchText)
=======
    
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
>>>>>>> mvc
    }
}
