//
//  RepositoryStore.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit

final class RepositoryStore {
    @Published
    private(set) var isRepositoryFetching = false

    @Published
    private(set) var favorites: [Repository] = []

    @Published
    private(set) var repositories: [Repository] = []

    @Published
    private(set) var selectedRepository: Repository?

    @Published
    private(set) var lastPageInfo: PageInfo?

    @Published
    private(set) var repositoryTotalCount: Int = 0

    private var cancellable = Set<AnyCancellable>()

    init(dispatcher: RepositoryDispatcher) {

        dispatcher.isRepositoryFetching
            .assign(to: \.isRepositoryFetching, on: self)
            .store(in: &cancellable)

        dispatcher.addRepositories
            .map { [weak self] repositories -> [Repository] in
                self.map { $0.repositories + repositories } ?? []
            }
            .assign(to: \.repositories, on: self)
            .store(in: &cancellable)

        dispatcher.removeAllRepositories
            .map { [] }
            .assign(to: \.repositories, on: self)
            .store(in: &cancellable)

        dispatcher.selectedRepository
            .assign(to: \.selectedRepository, on: self)
            .store(in: &cancellable)

        dispatcher.lastPageInfo
            .assign(to: \.lastPageInfo, on: self)
            .store(in: &cancellable)

        dispatcher.repositoryTotalCount
            .assign(to: \.repositoryTotalCount, on: self)
            .store(in: &cancellable)

        dispatcher.addFavorite
            .map { [weak self] favorite -> [Repository] in
                self.map { $0.favorites + [favorite] } ?? []
            }
            .assign(to: \.favorites, on: self)
            .store(in: &cancellable)

        dispatcher.removeFavorite
            .map { [weak self] favorite -> [Repository] in
                self.map { $0.favorites.filter { $0.url != favorite.url } } ?? []
            }
            .assign(to: \.favorites, on: self)
            .store(in: &cancellable)

        dispatcher.removeAllFavorites
            .map { [] }
            .assign(to: \.favorites, on: self)
            .store(in: &cancellable)
    }
}
