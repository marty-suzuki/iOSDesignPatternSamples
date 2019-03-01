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
    func showEmptyTokenError(errorMessage: ErrorMessage)
}

final class SearchViewController: UIViewController, SearchView {

    @IBOutlet private(set) weak var totalCountLabel: UILabel!
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var tableViewBottomConstraint: NSLayoutConstraint!

    let searchBar = UISearchBar(frame: .zero)
    let loadingView = LoadingView.makeFromNib()

    let favoritePresenter: FavoritePresenter
    let searchPresenter: SearchPresenter
    let dataSource: SearchViewDataSource

    init(searchPresenter: SearchPresenter, favoritePresenter: FavoritePresenter) {
        self.searchPresenter = searchPresenter
        self.favoritePresenter = favoritePresenter
        self.dataSource = SearchViewDataSource(presenter: searchPresenter)
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
        
        dataSource.configure(with: tableView)

        searchPresenter.view = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchPresenter.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
        searchPresenter.viewWillDisappear()
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
        let presenter = UserRepositoryViewPresenter(user: user)
        let vc = UserRepositoryViewController(userRepositoryPresenter: presenter, favoritePresenter: favoritePresenter)
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

    func showEmptyTokenError(errorMessage: ErrorMessage) {
        let alert = UIAlertController(title: errorMessage.message,
                                      message: errorMessage.message,
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
        searchPresenter.search(queryIfNeeded: searchText)
    }
}
