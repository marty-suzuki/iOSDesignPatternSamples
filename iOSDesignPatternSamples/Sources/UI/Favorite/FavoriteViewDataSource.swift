//
//  FavoriteViewDataSource.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/07.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit

final class FavoriteViewDataSource: NSObject {
    let favorites: () -> [Repository]
    let selectedFavorite: (Repository) -> ()
    
    init(favorites: @escaping () -> [Repository], selectedFavorite: @escaping (Repository) -> ()) {
        self.favorites = favorites
        self.selectedFavorite = selectedFavorite
        super.init()
    }
    
    func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.registerCell(RepositoryViewCell.self)
    }
}

extension FavoriteViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(RepositoryViewCell.self, for: indexPath)
        cell.configure(with: favorites()[indexPath.row])
        return cell
    }
}

extension FavoriteViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let repository = favorites()[indexPath.row]
        selectedFavorite(repository)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RepositoryViewCell.calculateHeight(with: favorites()[indexPath.row], and: tableView)
    }
}
