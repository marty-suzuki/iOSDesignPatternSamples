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
    private let viewModel: FavoriteViewModel
    
    init(viewModel: FavoriteViewModel) {
        self.viewModel = viewModel
    }
    
    func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(RepositoryViewCell.self)
    }
}

extension FavoriteViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(RepositoryViewCell.self, for: indexPath)
        let repository = viewModel.favorites[indexPath.row]
        cell.configure(with: repository)
        return cell
    }
}

extension FavoriteViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        viewModel.input.selectedIndexPath(indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let repository = viewModel.favorites[indexPath.row]
        return RepositoryViewCell.calculateHeight(with: repository, and: tableView)
    }
}
