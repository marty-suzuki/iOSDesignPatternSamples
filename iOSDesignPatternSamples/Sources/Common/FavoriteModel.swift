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
    var favoritePublisher: Published<[Repository]>.Publisher { get }
    func addFavorite(_ repository: Repository)
    func removeFavorite(_ repository: Repository)
    func contains(_ repository: Repository) -> AnyPublisher<Bool, Never>
}

final class FavoriteModel: FavoriteModelType {
    @Published
    private(set) var favorites: [Repository] = []
    var favoritePublisher: Published<[Repository]>.Publisher {
        $favorites
    }

    private let _addFavorite = PassthroughSubject<Repository, Never>()
    private let _removeFavorite = PassthroughSubject<Repository, Never>()
    private var cancellables = Set<AnyCancellable>()

    init() {
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
            .assign(to: \.favorites, on: self)
            .store(in: &cancellables)
    }

    func addFavorite(_ repository: Repository) {
        _addFavorite.send(repository)
    }

    func removeFavorite(_ repository: Repository) {
        _removeFavorite.send(repository)
    }

    func contains(_ repository: Repository) -> AnyPublisher<Bool, Never> {
        $favorites
            .map { $0.contains { $0.url == repository.url } }
            .eraseToAnyPublisher()
    }
}
