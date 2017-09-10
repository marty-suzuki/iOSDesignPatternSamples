//
//  FavoritePresenter.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit

protocol FavoritePresenter: class {
    init(view: FavoriteView)
    var numberOfFavorites: Int { get }
    func addFavorite(_ repository: Repository)
    func removeFavorite(_ repository: Repository)
    func favoriteRepository(at index: Int) -> Repository
    func showFavoriteRepository(at index: Int)
    func contains(_ repository: Repository) -> Bool
}

final class FavoriteViewPresenter: FavoritePresenter {
    private weak var view: FavoriteView?
    private var favorites: [Repository] = [] {
        didSet {
            view?.reloadData()
        }
    }
    
    var numberOfFavorites: Int {
        return favorites.count
    }
    
    init(view: FavoriteView) {
        self.view = view
    }
    
    func favoriteRepository(at index: Int) -> Repository {
        return favorites[index]
    }
    
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
    
    func contains(_ repository: Repository) -> Bool {
        return favorites.lazy.index { $0.url == repository.url } != nil
    }
    
    func showFavoriteRepository(at index: Int) {
        let repository = favorites[index]
        view?.showRepository(with: repository)
    }
}
