//
//  SearchViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit
import NoticeObserveKit

final class SearchViewController: UIViewController {
    
    @IBOutlet weak var totalCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    private(set) lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = self
        return searchBar
    }()
    
    fileprivate var query: String = "" {
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
    fileprivate var users: [User] = [] {
        didSet {
            totalCountLabel.text = "\(users.count) / \(totalCount)"
            tableView.reloadData()
        }
    }
    fileprivate let debounce: (_ action: @escaping () -> ()) -> () = {
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
    fileprivate var isFetchingUsers = false {
        didSet {
            tableView.reloadData()
        }
    }
    private var pool = NoticeObserverPool()
    
    fileprivate let loadingView = LoadingView.makeFromNib()
    
    fileprivate var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                fetchUsers()
            }
        }
    }
    
    var favoriteModel: FavoriteModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = searchBar
        searchBar.placeholder = "Input user name"
        
        configure(with: tableView)
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
        pool = NoticeObserverPool()
    }
    
    private func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UserViewCell.self)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.className)
    }
    
    private func observeKeyboard() {
        UIKeyboardWillShow.observe { [weak self] in
            self?.view.layoutIfNeeded()
            let extra = self?.tabBarController?.tabBar.bounds.height ?? 0
            self?.tableViewBottomConstraint.constant = $0.frame.size.height - extra
            UIView.animate(withDuration: $0.animationDuration, delay: 0, options: $0.animationCurve, animations: {
                self?.view.layoutIfNeeded()
            }, completion: nil)
        }
        .disposed(by: pool)
        
        UIKeyboardWillHide.observe { [weak self] in
            self?.view.layoutIfNeeded()
            self?.tableViewBottomConstraint.constant = 0
            UIView.animate(withDuration: $0.animationDuration, delay: 0, options: $0.animationCurve, animations: {
                self?.view.layoutIfNeeded()
            }, completion: nil)
        }
        .disposed(by: pool)
    }
    
    private func fetchUsers() {
        if query.isEmpty || task != nil { return }
        if let pageInfo = pageInfo, !pageInfo.hasNextPage || pageInfo.endCursor == nil { return }
        isFetchingUsers = true
        let request = SearchUserRequest(query: query, after: pageInfo?.endCursor)
        self.task = ApiSession.shared.send(request) { [weak self] in
            switch $0 {
            case .success(let value):
                DispatchQueue.main.async {
                    self?.pageInfo = value.pageInfo
                    self?.users.append(contentsOf: value.nodes)
                    self?.totalCount = value.totalCount
                }
            case .failure(let error):
                if case .emptyToken? = (error as? ApiSession.Error) {
                    DispatchQueue.main.async {
                        guard let me = self else { return }
                        let message = "\"Github Personal Access Token\" is Required.\n Please set it in ApiSession.extension.swift!"
                        let alert = UIAlertController(title: "Access Token Error",
                                                      message: message,
                                                      preferredStyle: .alert)
                        me.present(alert, animated: false, completion: nil)
                    }
                }
            }
            DispatchQueue.main.async {
                self?.isFetchingUsers = false
            }
            self?.task = nil
        }
    }
    
    fileprivate func showUserRepository(with user: User) {
        guard let favoriteModel = favoriteModel else { return }
        let vc = UserRepositoryViewController(user: user, favoriteModel: favoriteModel)
        navigationController?.pushViewController(vc, animated: true)
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
        debounce { [weak self] in
            self?.query = searchText
        }
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UserViewCell.self, for: indexPath)
        cell.configure(with: users[indexPath.row])
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
        loadingView.isLoading = isFetchingUsers
        loadingView.add(to: view)
        return view
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let user = users[indexPath.row]
        showUserRepository(with: user)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UserViewCell.calculateHeight(with: users[indexPath.row], and: tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return isFetchingUsers ? LoadingView.defaultHeight : .leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
        isReachedBottom = maxScrollDistance <= scrollView.contentOffset.y
    }
}
