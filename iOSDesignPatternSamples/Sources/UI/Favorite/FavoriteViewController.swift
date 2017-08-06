//
//  FavoriteViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

final class FavoriteViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var favorites: [Repository] {
        return (UIApplication.shared.delegate as? AppDelegate)?.favorites ?? []
    }
    
    private(set) lazy var dataSource: FavoriteViewDataSource = {
        return .init(favorites: { [weak self] in
            return self?.favorites ?? []
        }, selectedFavorite: { [weak self] repository in
            self?.showRepository(with: repository)
        })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"
        automaticallyAdjustsScrollViewInsets = false
        
        dataSource.configure(with: tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    private func showRepository(with repository: Repository) {
        let vc = RepositoryViewController(repository: repository)
        navigationController?.pushViewController(vc, animated: true)
    }
}
