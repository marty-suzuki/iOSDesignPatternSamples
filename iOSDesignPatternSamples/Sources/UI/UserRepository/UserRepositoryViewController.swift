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
    private let user: User
    private let favoritePresenter: FavoritePresenter
    
    private lazy var presenter: UserRepositoryViewPresenter = .init(view: self, user: self.user)
    private lazy var dataSource: UserRepositoryViewDataSource = .init(presenter: self.presenter)
    
    init(user: User, favoritePresenter: FavoritePresenter) {
        self.user = user
        self.favoritePresenter = favoritePresenter
        
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
        presenter.fetchRepositories()
    }
    
    func showRepository(with repository: Repository) {
        let vc = RepositoryViewController(repository: repository, favoritePresenter: favoritePresenter)
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
