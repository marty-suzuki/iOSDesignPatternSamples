//
//  UserRepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import GithubKit
import UIKit

protocol UserRepositoryView: class {
    func reloadData()
    func showRepository(with repository: Repository)
    func updateTotalCountLabel(_ countText: String)
    func updateLoadingView(with view: UIView, isLoading: Bool)
}

final class UserRepositoryViewController: UIViewController, UserRepositoryView {

    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var totalCountLabel: UILabel!

    let loadingView = LoadingView()

    let userRepositoryPresenter: UserRepositoryPresenter
    let dataSource: UserRepositoryViewDataSource

    private let makeRepositoryPresenter: (Repository) -> RepositoryPresenter
    
    init(
        userRepositoryPresenter: UserRepositoryPresenter,
        makeRepositoryPresenter: @escaping (Repository) -> RepositoryPresenter
    ) {
        self.userRepositoryPresenter = userRepositoryPresenter
        self.dataSource = UserRepositoryViewDataSource(presenter: userRepositoryPresenter)
        self.makeRepositoryPresenter = makeRepositoryPresenter
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = userRepositoryPresenter.title
        
        dataSource.configure(with: tableView)

        userRepositoryPresenter.view = self
        userRepositoryPresenter.fetchRepositories()
    }
    
    func showRepository(with repository: Repository) {
        let repositoryPresenter = makeRepositoryPresenter(repository)
        let vc = RepositoryViewController(presenter: repositoryPresenter)
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
