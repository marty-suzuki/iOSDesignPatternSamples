//
//  FavoriteViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

<<<<<<< HEAD
protocol FavoriteView: class {
    func reloadData()
    func showRepository(with repository: Repository)
}

final class FavoriteViewController: UIViewController, FavoriteView {
    @IBOutlet weak var tableView: UITableView!

    private(set) lazy var presenter: FavoritePresenter = FavoriteViewPresenter(view: self)
    private lazy var dataSource: FavoriteViewDataSource = .init(presenter: self.presenter)

=======
final class FavoriteViewController: UIViewController {
    @IBOutlet private(set) weak var tableView: UITableView!
    
    let favoriteModel: FavoriteModel

    init(favoriteModel: FavoriteModel) {
        self.favoriteModel = favoriteModel
        super.init(nibName: FavoriteViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
>>>>>>> mvc
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"

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
