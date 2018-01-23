//
//  UserRepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

final class UserRepositoryViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalCountLabel: UILabel!

    fileprivate let loadingView = LoadingView.makeFromNib()
    
    fileprivate var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                fetchRepositories()
            }
        }
    }
    fileprivate var isFetchingRepositories = false {
        didSet {
            tableView.reloadData()
        }
    }
    private var totalCount: Int = 0 {
        didSet {
            totalCountLabel.text = "\(repositories.count) / \(totalCount)"
        }
    }
    fileprivate var repositories: [Repository] = []  {
        didSet {
            totalCountLabel.text = "\(repositories.count) / \(totalCount)"
            tableView.reloadData()
        }
    }
    private var pageInfo: PageInfo? = nil
    private var task: URLSessionTask? = nil
    
    private let user: User
    private let favoriteModel: FavoriteModel
    
    init(user: User, favoriteModel: FavoriteModel) {
        self.user = user
        self.favoriteModel = favoriteModel
        
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "\(user.login)'s Repositories"
        edgesForExtendedLayout = []
        
        configure(with: tableView)
        
        fetchRepositories()
    }
    
    private func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(RepositoryViewCell.self)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.className)
    }
    
    fileprivate func fetchRepositories() {
        if task != nil { return }
        if let pageInfo = pageInfo, !pageInfo.hasNextPage || pageInfo.endCursor == nil { return }
        isFetchingRepositories = true
        let request = UserNodeRequest(id: user.id, after: pageInfo?.endCursor)
        self.task = ApiSession.shared.send(request) { [weak self] in
            switch $0 {
            case .success(let value):
                DispatchQueue.main.async {
                    self?.pageInfo = value.pageInfo
                    self?.repositories.append(contentsOf: value.nodes)
                    self?.totalCount = value.totalCount
                }
            case .failure(let error):
                print(error)
            }
            DispatchQueue.main.async {
                self?.isFetchingRepositories = false
            }
            self?.task = nil
        }
    }
    
    fileprivate func showRepository(with repository: Repository) {
        let vc = RepositoryViewController(repository: repository, favoriteModel: favoriteModel)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension UserRepositoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(RepositoryViewCell.self, for: indexPath)
        cell.configure(with: repositories[indexPath.row])
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
        loadingView.isLoading = isFetchingRepositories
        loadingView.add(to: view)
        return view
    }
}

extension UserRepositoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let repository = repositories[indexPath.row]
        showRepository(with: repository)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RepositoryViewCell.calculateHeight(with: repositories[indexPath.row], and: tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return isFetchingRepositories ? LoadingView.defaultHeight : .leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
        isReachedBottom = maxScrollDistance <= scrollView.contentOffset.y
    }
}
