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
    @IBOutlet private(set) weak var tableView: UITableView!
    
    let favoriteModel: FavoriteModelType

    init(favoriteModel: FavoriteModelType) {
        self.favoriteModel = favoriteModel
        super.init(nibName: FavoriteViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"
        
        favoriteModel.delegate = self
        configure(with: tableView)
    }
    
    private func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(RepositoryViewCell.self)
    }
    
    private func showRepository(with repository: Repository) {
        let vc = RepositoryViewController(repository: repository, favoriteModel: favoriteModel)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension FavoriteViewController: FavoriteModelDelegate {
    func favoriteDidChange() {
        tableView.reloadData()
    }
}

extension FavoriteViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteModel.favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(RepositoryViewCell.self, for: indexPath)
        cell.configure(with: favoriteModel.favorites[indexPath.row])
        return cell
    }
}

extension FavoriteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let repository = favoriteModel.favorites[indexPath.row]
        showRepository(with: repository)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RepositoryViewCell.calculateHeight(with: favoriteModel.favorites[indexPath.row], and: tableView)
    }
}
