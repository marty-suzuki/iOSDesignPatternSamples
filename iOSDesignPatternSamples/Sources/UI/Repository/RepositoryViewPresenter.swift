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
    init(repository: Repository, favoritePresenter: FavoritePresenter)
    var view: RepositoryView? { get set }
    var url: URL { get }
    var favoriteButtonTitle: String { get }
    func favoriteButtonTap()
}

final class RepositoryViewPresenter: RepositoryPresenter {
    weak var view: RepositoryView?
    private let favoritePresenter: FavoritePresenter
    private let repository: Repository
    
    var favoriteButtonTitle: String {
        return favoritePresenter.contains(repository) ? "Remove" : "Add"
    }

    var url: URL {
        return repository.url
    }
    
    init(repository: Repository, favoritePresenter: FavoritePresenter) {
        self.repository = repository
        self.favoritePresenter = favoritePresenter
    }
    
    func favoriteButtonTap() {
        if favoritePresenter.contains(repository) {
            favoritePresenter.removeFavorite(repository)
            view?.updateFavoriteButtonTitle(favoriteButtonTitle)
        } else {
            favoritePresenter.addFavorite(repository)
            view?.updateFavoriteButtonTitle(favoriteButtonTitle)
        }
    }
}
