//
//  UserRepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

protocol UserRepositoryView: class {
    func reloadData()
    func showRepository(with repository: Repository)
    func updateTotalCountLabel(_ countText: String)
    func updateLoadingView(with view: UIView, isLoading: Bool)
}

final class UserRepositoryViewController: UIViewController, UserRepositoryView {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalCountLabel: UILabel!

    private let loadingView = LoadingView.makeFromNib()
<<<<<<< HEAD
    private let favoritePresenter: FavoritePresenter
    private let presenter: UserRepositoryPresenter
=======
    
    private var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                fetchRepositories()
            }
        }
    }
    private var isFetchingRepositories = false {
        didSet {
            tableView.reloadData()
        }
    }
    private var totalCount: Int = 0 {
        didSet {
            totalCountLabel.text = "\(repositories.count) / \(totalCount)"
        }
    }
    private var repositories: [Repository] = []  {
        didSet {
            totalCountLabel.text = "\(repositories.count) / \(totalCount)"
            tableView.reloadData()
        }
    }
    private var pageInfo: PageInfo? = nil
    private var task: URLSessionTask? = nil
>>>>>>> mvc
    
    private lazy var dataSource: UserRepositoryViewDataSource = .init(presenter: self.presenter)
    
    init(user: User, favoritePresenter: FavoritePresenter) {
        self.favoritePresenter = favoritePresenter
        self.presenter = UserRepositoryViewPresenter(user: user)
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
        presenter.view = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
<<<<<<< HEAD
        title = presenter.title
        edgesForExtendedLayout = []
        
        dataSource.configure(with: tableView)
        presenter.fetchRepositories()
    }
    
    func showRepository(with repository: Repository) {
        let vc = RepositoryViewController(repository: repository, favoritePresenter: favoritePresenter)
=======
        title = "\(user.login)'s Repositories"
        
        configure(with: tableView)
        
        fetchRepositories()
    }
    
    private func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(RepositoryViewCell.self)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.className)
    }
    
    private func fetchRepositories() {
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
    
    private func showRepository(with repository: Repository) {
        let vc = RepositoryViewController(repository: repository, favoriteModel: favoriteModel)
>>>>>>> mvc
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    func updateTotalCountLabel(_ countText: String) {
        totalCountLabel.text = countText
    }
    
    func updateLoadingView(with view: UIView, isLoading: Bool) {
        loadingView.removeFromSuperview()
        loadingView.isLoading = isLoading
        loadingView.add(to: view)
    }
}
