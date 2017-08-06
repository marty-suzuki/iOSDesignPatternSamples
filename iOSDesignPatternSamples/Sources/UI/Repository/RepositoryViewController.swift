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
        let favorites = self.favoriteHandlable?.getFavorites() ?? []
        let title = favorites.contains(where: { $0.url == self.repository.url }) ? "Remove" : "Add"
        return UIBarButtonItem(title: title,
                               style: .plain,
                               target: self,
                               action: #selector(RepositoryViewController.favoriteButtonTap(_:)))
    }()
    
    private let repository: Repository
    private weak var favoriteHandlable: FavoriteHandlable?
    
    init(repository: Repository,
         favoriteHandlable: FavoriteHandlable?,
         entersReaderIfAvailable: Bool = true) {
        self.repository = repository
        self.favoriteHandlable = favoriteHandlable
        
        super.init(url: repository.url, entersReaderIfAvailable: entersReaderIfAvailable)
        hidesBottomBarWhenPushed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = favoriteButtonItem
    }
    
    @objc private func favoriteButtonTap(_ sender: UIBarButtonItem) {
        var favorites = favoriteHandlable?.getFavorites() ?? []
        if let index = favorites.index(where: { $0.url == repository.url }) {
            favorites.remove(at: index)
            favoriteButtonItem.title = "Add"
        } else {
            favorites.append(repository)
            favoriteButtonItem.title = "Remove"
        }
        favoriteHandlable?.setFavorites(favorites)
    }
}
