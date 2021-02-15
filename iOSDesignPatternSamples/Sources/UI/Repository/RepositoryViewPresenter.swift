//
//  RepositoryViewPresenter.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/11.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit

protocol RepositoryPresenter: class {
    var view: RepositoryView? { get set }
    var url: URL { get }
    var favoriteButtonTitle: String { get }
    func favoriteButtonTap()
}

final class RepositoryViewPresenter: RepositoryPresenter {
    weak var view: RepositoryView?
    private let favoriteModel: FavoriteModelType
    private let repository: Repository
    
    var favoriteButtonTitle: String {
        return favoriteModel.favorites.contains(repository) ? "Remove" : "Add"
    }

    var url: URL {
        return repository.url
    }
    
    init(
        repository: Repository,
        favoriteModel: FavoriteModelType
    ) {
        self.repository = repository
        self.favoriteModel = favoriteModel
    }
    
    func favoriteButtonTap() {
        if favoriteModel.favorites.contains(repository) {
            favoriteModel.removeFavorite(repository)
            view?.updateFavoriteButtonTitle(favoriteButtonTitle)
        } else {
            favoriteModel.addFavorite(repository)
            view?.updateFavoriteButtonTitle(favoriteButtonTitle)
        }
    }
}
