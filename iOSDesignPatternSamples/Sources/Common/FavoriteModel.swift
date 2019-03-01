//
//  FavoriteModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/28.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import GithubKit

@objc protocol FavoriteModelDelegate: class {
    @objc optional func favoriteDidChange()
}

final class FavoriteModel {
    private(set) var favorites: [Repository] = [] {
        didSet {
            delegate?.favoriteDidChange?()
        }
    }
    
    weak var delegate: FavoriteModelDelegate?
    
    func addFavorite(_ repository: Repository) {
        if favorites.lazy.index(where: { $0.url == repository.url }) != nil {
            return
        }
        favorites.append(repository)
    }
    
    func removeFavorite(_ repository: Repository) {
        guard let index = favorites.lazy.index(where: { $0.url == repository.url }) else {
            return
        }
        favorites.remove(at: index)
    }
}
