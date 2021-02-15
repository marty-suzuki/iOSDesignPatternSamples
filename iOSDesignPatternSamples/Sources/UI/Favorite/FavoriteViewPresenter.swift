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
    var view: FavoriteView? { get set }
    var numberOfFavorites: Int { get }
    func favoriteRepository(at index: Int) -> Repository
    func showFavoriteRepository(at index: Int)
}

final class FavoriteViewPresenter: FavoritePresenter {
    weak var view: FavoriteView?

    var numberOfFavorites: Int {
        return model.favorites.count
    }

    private let model: FavoriteModelType

    init(model: FavoriteModelType) {
        self.model = model
        self.model.delegate = self
    }
    
    func favoriteRepository(at index: Int) -> Repository {
        return model.favorites[index]
    }
    
    func showFavoriteRepository(at index: Int) {
        let repository = model.favorites[index]
        view?.showRepository(with: repository)
    }
}

extension FavoriteViewPresenter: FavoriteModelDelegate {
    func favoriteDidChange() {
        view?.reloadData()
    }
}
