//
//  FavoriteViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

protocol FavoriteView: class {
    func reloadData()
    func showRepository(with repository: Repository)
}

final class FavoriteViewController: UIViewController, FavoriteView {
    @IBOutlet weak var tableView: UITableView!
    
    private(set) lazy var presenter: FavoritePresenter = FavoriteViewPresenter(view: self)
    private lazy var dataSource: FavoriteViewDataSource = .init(presenter: self.presenter)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"
        automaticallyAdjustsScrollViewInsets = false
        
        dataSource.configure(with: tableView)
    }
    
    func showRepository(with repository: Repository) {
        let vc = RepositoryViewController(repository: repository, favoritePresenter: presenter)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func reloadData() {
        tableView?.reloadData()
    }
}
