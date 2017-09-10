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
        let title = self.favoritePresenter.contains(self.repository) ? "Remove" : "Add"
        return UIBarButtonItem(title: title,
                               style: .plain,
                               target: self,
                               action: #selector(RepositoryViewController.favoriteButtonTap(_:)))
    }()
    
    private let repository: Repository
    private let favoritePresenter: FavoritePresenter
    
    init(repository: Repository,
         favoritePresenter: FavoritePresenter,
         entersReaderIfAvailable: Bool = true) {
        self.repository = repository
        self.favoritePresenter = favoritePresenter
        
        super.init(url: repository.url, entersReaderIfAvailable: entersReaderIfAvailable)
        hidesBottomBarWhenPushed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = favoriteButtonItem
    }
    
    @objc private func favoriteButtonTap(_ sender: UIBarButtonItem) {
        if favoritePresenter.contains(repository) {
            favoritePresenter.removeFavorite(repository)
            favoriteButtonItem.title = "Add"
        } else {
            favoritePresenter.addFavorite(repository)
            favoriteButtonItem.title = "Remove"
        }
    }
}
