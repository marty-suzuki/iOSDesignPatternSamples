//
//  FavoriteViewDataSource.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import UIKit
import GithubKit
import RxSwift

final class FavoriteViewDataSource: NSObject {
<<<<<<< HEAD
    private let store: RepositoryStore
    private let action: RepositoryAction

    init(store: RepositoryStore = .instantiate(),
         action: RepositoryAction = .init()) {
        self.store = store
        self.action = action
=======
    private let viewModel: FavoriteViewModel
    
    init(viewModel: FavoriteViewModel) {
        self.viewModel = viewModel
>>>>>>> mvvm
    }
    
    func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(RepositoryViewCell.self)
    }
}

extension FavoriteViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
<<<<<<< HEAD
        return store.value.favorites.count
=======
        return viewModel.favorites.count
>>>>>>> mvvm
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(RepositoryViewCell.self, for: indexPath)
<<<<<<< HEAD
        let repository = store.value.favorites[indexPath.row]
=======
        let repository = viewModel.favorites[indexPath.row]
>>>>>>> mvvm
        cell.configure(with: repository)
        return cell
    }
}

extension FavoriteViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
<<<<<<< HEAD
        let repository = store.value.favorites[indexPath.row]
        action.selectRepository(repository)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let repository = store.value.favorites[indexPath.row]
=======
        viewModel.input.selectedIndexPath.onNext(indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let repository = viewModel.favorites[indexPath.row]
>>>>>>> mvvm
        return RepositoryViewCell.calculateHeight(with: repository, and: tableView)
    }
}
