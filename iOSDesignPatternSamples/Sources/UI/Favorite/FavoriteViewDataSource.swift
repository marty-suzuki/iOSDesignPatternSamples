//
//  FavoriteViewDataSource.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit
import UIKit

final class FavoriteViewDataSource: NSObject {
    private let store: RepositoryStore
    private let action: RepositoryAction

    init(flux: Flux) {
        self.store = flux.repositoryStore
        self.action = flux.repositoryAction
    }

    func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(RepositoryViewCell.self)
    }
}

extension FavoriteViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.favorites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(RepositoryViewCell.self, for: indexPath)
        let repository = store.favorites[indexPath.row]
        cell.configure(with: repository)
        return cell
    }
}

extension FavoriteViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let repository = store.favorites[indexPath.row]
        action.selectRepository(repository)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let repository = store.favorites[indexPath.row]
        return RepositoryViewCell.calculateHeight(with: repository, and: tableView)
    }
}
