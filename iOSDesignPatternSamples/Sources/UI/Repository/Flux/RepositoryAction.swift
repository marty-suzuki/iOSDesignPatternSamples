//
//  RepositoryAction.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import Foundation
import GithubKit

protocol RepositoryActionType: AnyObject {
    func toggleFavorite()
    func load()
}

final class RepositoryAction: RepositoryActionType {
    private let favoriteModel: FavoriteModelType
    private let _toggleFavorite = PassthroughSubject<Void, Never>()
    private let _load = PassthroughSubject<Void, Never>()
    private var cancellable = Set<AnyCancellable>()

    init(
        repository: Repository,
        dispatcher: RepositoryDispatcher,
        favoriteModel: FavoriteModelType
    ) {
        self.favoriteModel = favoriteModel

        _load
            .map { favoriteModel.contains(repository) }
            .switchToLatest()
            .map { $0 ? "Remove" : "Add" }
            .sink(receiveValue: dispatcher.favoriteButtonTitle.send)
            .store(in: &cancellable)

        _toggleFavorite
            .flatMap {
                favoriteModel.contains(repository)
                    .prefix(1)
            }
            .sink { contains in
                if contains {
                    favoriteModel.removeFavorite(repository)
                } else {
                    favoriteModel.addFavorite(repository)
                }
            }
            .store(in: &cancellable)
    }

    func toggleFavorite() {
        _toggleFavorite.send()
    }

    func load() {
        _load.send()
    }
}
