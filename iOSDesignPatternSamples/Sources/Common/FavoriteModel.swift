//
//  FavoriteModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/28.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import GithubKit

protocol FavoriteModelDelegate: AnyObject {
    func favoriteDidChange()
}

extension FavoriteModelDelegate {
    func favoriteDidChange() {}
}

protocol FavoriteModelType: AnyObject {
    var favorites: [Repository] { get }
    var delegate: FavoriteModelDelegate? { get set }
    func addFavorite(_ repository: Repository)
    func removeFavorite(_ repository: Repository)
}

final class FavoriteModel: FavoriteModelType {
    private(set) var favorites: [Repository] = [] {
        didSet {
            delegate?.favoriteDidChange()
        }
    }
    
    weak var delegate: FavoriteModelDelegate?
    
    func addFavorite(_ repository: Repository) {
        if favorites.firstIndex(where: { $0.url == repository.url }) != nil {
            return
        }
        favorites.append(repository)
    }
    
    func removeFavorite(_ repository: Repository) {
        guard let index = favorites.firstIndex(where: { $0.url == repository.url }) else {
            return
        }
        favorites.remove(at: index)
    }
}
