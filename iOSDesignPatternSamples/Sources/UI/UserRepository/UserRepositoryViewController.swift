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
    
    private lazy var dataSource: UserRepositoryViewDataSource = {
        return .init(fetchRepositories: { [weak self] in
            self?.fetchRepositories()
        }, repositories: { [weak self] in
            return self?.repositories ?? []
        }, isFetchingRepositories: { [weak self] in
            return self?.isFetchingRepositories ?? false
        }, selectedRepository: { [weak self] repository in
            self?.showRepository(with: repository)
        })
    }()
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
    
    private let user: User
    
    init(user: User) {
        self.user = user
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
        
        dataSource.configure(with: tableView)
        
        fetchRepositories()
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
        
    }
}
