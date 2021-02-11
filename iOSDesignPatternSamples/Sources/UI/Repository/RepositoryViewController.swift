//
//  RepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import SafariServices
import GithubKit

final class RepositoryViewController: SFSafariViewController {
    private(set) lazy var favoriteButtonItem: UIBarButtonItem = {
        let favorites = self.favoriteModel.favorites
        let title = favorites.contains(where: { $0.url == self.repository.url }) ? "Remove" : "Add"
        return UIBarButtonItem(title: title,
                               style: .plain,
                               target: self,
                               action: #selector(RepositoryViewController.favoriteButtonTap(_:)))
    }()
    
    let repository: Repository
    let favoriteModel: FavoriteModelType
    
    init(repository: Repository, favoriteModel: FavoriteModelType) {
        self.repository = repository
        self.favoriteModel = favoriteModel

        super.init(url: repository.url, configuration: .init())
        hidesBottomBarWhenPushed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = favoriteButtonItem
    }
    
    @objc private func favoriteButtonTap(_ sender: UIBarButtonItem) {
        if favoriteModel.favorites.first(where: { $0.url == repository.url }) == nil {
            favoriteModel.addFavorite(repository)
            favoriteButtonItem.title = "Remove"
        } else {
            favoriteModel.removeFavorite(repository)
            favoriteButtonItem.title = "Add"
        }
    }
}
