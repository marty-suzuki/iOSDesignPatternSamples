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

protocol RepositoryView: class {
    func updateFavoriteButtonTitle(_ title: String)
}

final class RepositoryViewController: SFSafariViewController, RepositoryView {
    private(set) lazy var favoriteButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(title: self.presenter.favoriteButtonTitle,
                               style: .plain,
                               target: self,
                               action: #selector(RepositoryViewController.favoriteButtonTap(_:)))
    }()
    private let presenter: RepositoryPresenter
    
    init(presenter: RepositoryPresenter) {
        self.presenter = presenter
        super.init(url: presenter.url, configuration: .init())
        hidesBottomBarWhenPushed = true

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = favoriteButtonItem

        presenter.view = self
    }
    
    @objc private func favoriteButtonTap(_ sender: UIBarButtonItem) {
        presenter.favoriteButtonTap()
    }
    
    func updateFavoriteButtonTitle(_ title: String) {
        favoriteButtonItem.title = title
    }
}
