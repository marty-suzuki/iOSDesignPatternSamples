//
//  FavoriteModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/28.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit

protocol FavoriteModelType: AnyObject {
    var favorites: [Repository] { get }
    var contains: AnyPublisher<(Bool, Repository), Never> { get }
    func addFavorite(_ repository: Repository)
    func removeFavorite(_ repository: Repository)
}

final class FavoriteModel: FavoriteModelType {

    let contains: AnyPublisher<(Bool, Repository), Never>

    private let _addFavorite = PassthroughSubject<Repository, Never>()
    private let _removeFavorite = PassthroughSubject<Repository, Never>()

    @Published
    private(set) var favorites: [Repository] = []
    private var cancellables = Set<AnyCancellable>()

    init(
        repository: Repository,
        favoritesInput: @escaping ([Repository]) -> Void,
        favoritesOutput: AnyPublisher<[Repository], Never>
    ) {

        self.contains = favoritesOutput
            .map { favorites in
                (favorites.contains { $0.url == repository.url }, repository)
            }
            .eraseToAnyPublisher()

        do {
            let favorites1 = _addFavorite
                .flatMap { [weak self] repository -> AnyPublisher<[Repository], Never> in
                    guard let me = self else {
                        return Empty().eraseToAnyPublisher()
                    }
                    var favorites = me.favorites
                    if favorites.firstIndex(where: { $0.url == repository.url }) != nil {
                        return Empty().eraseToAnyPublisher()
                    }
                    favorites.append(repository)
                    return Just(favorites).eraseToAnyPublisher()
                }

            let favorites2 = _removeFavorite
                .flatMap { [weak self] repository -> AnyPublisher<[Repository], Never> in
                    guard let me = self else {
                        return Empty().eraseToAnyPublisher()
                    }
                    var favorites = me.favorites
                    guard let index = favorites.firstIndex(where: { $0.url == repository.url }) else {
                        return Empty().eraseToAnyPublisher()
                    }
                    favorites.remove(at: index)
                    return Just(favorites).eraseToAnyPublisher()
                }

            favorites1.merge(with: favorites2)
                .sink { favorites in
                    favoritesInput(favorites)
                }
                .store(in: &cancellables)
        }

        favoritesOutput
            .assign(to: \.favorites, on: self)
            .store(in: &cancellables)
    }

    func addFavorite(_ repository: Repository) {
        _addFavorite.send(repository)
    }

    func removeFavorite(_ repository: Repository) {
        _removeFavorite.send(repository)
    }
}
