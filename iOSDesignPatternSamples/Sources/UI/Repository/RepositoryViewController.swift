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
    private var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    private var bookmarks: [Repository] {
        return appDelegate?.bookmarks ?? []
    }
    
    private(set) lazy var favoriteButtonItem: UIBarButtonItem = {
        let title = self.bookmarks.contains(where: { $0.url == self.repository.url }) ? "Remove" : "Add"
        return UIBarButtonItem(title: title,
                               style: .plain,
                               target: self,
                               action: #selector(RepositoryViewController.favoriteButtonTap(_:)))
    }()
    
    private let repository: Repository
    
    init(repository: Repository,
         entersReaderIfAvailable: Bool = true) {
        self.repository = repository
        
        super.init(url: repository.url, entersReaderIfAvailable: entersReaderIfAvailable)
        hidesBottomBarWhenPushed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = favoriteButtonItem
    }
    
    @objc private func favoriteButtonTap(_ sender: UIBarButtonItem) {
        if bookmarks.contains(where: { $0.url == repository.url }) {
            appDelegate?.removeBookmark(repository)
            favoriteButtonItem.title = "Add"
        } else {
            appDelegate?.addBookmark(repository)
            favoriteButtonItem.title = "Remove"
        }
    }
}
