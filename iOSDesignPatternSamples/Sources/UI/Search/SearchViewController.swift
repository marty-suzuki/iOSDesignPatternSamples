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
    
    fileprivate let loadingView = LoadingView.makeFromNib()
    
    var favoritePresenter: FavoritePresenter?
    
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
