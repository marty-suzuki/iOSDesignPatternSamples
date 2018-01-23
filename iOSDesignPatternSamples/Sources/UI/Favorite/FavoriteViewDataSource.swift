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
    private let selectedIndexPath: AnyObserver<IndexPath>
    private let viewModel: FavoriteViewModel
    
    init(viewModel: FavoriteViewModel,
         selectedIndexPath: AnyObserver<IndexPath>) {
        self.viewModel = viewModel
        self.selectedIndexPath = selectedIndexPath
    }
    
    func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(RepositoryViewCell.self)
    }
}

extension FavoriteViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.value.favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(RepositoryViewCell.self, for: indexPath)
        let repository = viewModel.value.favorites[indexPath.row]
        cell.configure(with: repository)
        return cell
    }
}

extension FavoriteViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        selectedIndexPath.onNext(indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let repository = viewModel.value.favorites[indexPath.row]
        return RepositoryViewCell.calculateHeight(with: repository, and: tableView)
    }
}
