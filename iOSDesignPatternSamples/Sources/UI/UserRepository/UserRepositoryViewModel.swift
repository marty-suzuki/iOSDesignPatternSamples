//
//  UserRepositoryViewModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import Foundation
import GithubKit
import UIKit

final class UserRepositoryViewModel {
    let title: String

    var repositories: [Repository] {
        return model.repositories
    }

    var isFetchingRepositories: Bool {
        return model.isFetchingRepositories
    }

    let output: Output
    let input: Input

    private let model: RepositoryModel
    private var cancellables = Set<AnyCancellable>()

    init(user: User,
         favoritesOutput: AnyPublisher<[Repository], Never>,
         favoritesInput: @escaping ([Repository]) -> Void) {
        self.title = "\(user.login)'s Repositories"

        let model = RepositoryModel(user: user)
        self.model = model

        let _fetchRepositories = PassthroughSubject<Void, Never>()
        let _selectedIndexPath = PassthroughSubject<IndexPath, Never>()
        let _isReachedBottom = PassthroughSubject<Bool, Never>()
        let _headerFooterView = PassthroughSubject<UIView, Never>()

        self.input = Input(fetchRepositories: _fetchRepositories.send,
                           selectedIndexPath: _selectedIndexPath.send,
                           isReachedBottom: _isReachedBottom.send,
                           headerFooterView: _headerFooterView.send,
                           favorites: favoritesInput)

        do {
            let updateLoadingView = _headerFooterView
                .combineLatest(model.isFetchingRepositoriesPublisher)
                .eraseToAnyPublisher()

            let showRepository = _selectedIndexPath
                .map { model.repositories[$0.row] }
                .eraseToAnyPublisher()

            let countString = model.totalCountPublisher
                .combineLatest(model.repositoriesPublisher)
                .map { "\($1.count) / \($0)" }
                .eraseToAnyPublisher()

            let reloadData = model.repositoriesPublisher.map { _ in }
                .merge(
                    with:
                        model.totalCountPublisher.map { _ in },
                        model.isFetchingRepositoriesPublisher.map { _ in }
                )
                .eraseToAnyPublisher()

            self.output = Output(updateLoadingView: updateLoadingView,
                                 showRepository: showRepository,
                                 countString: countString,
                                 reloadData: reloadData,
                                 favorites: favoritesOutput)
        }

        _isReachedBottom
            .removeDuplicates()
            .filter { $0 }
            .sink { _ in
                model.fetchRepositories()
            }
            .store(in: &cancellables)

        model.fetchRepositories()
    }
}

extension UserRepositoryViewModel {
    struct Output {
        let updateLoadingView: AnyPublisher<(UIView, Bool), Never>
        let showRepository: AnyPublisher<Repository, Never>
        let countString: AnyPublisher<String, Never>
        let reloadData: AnyPublisher<Void, Never>
        let favorites: AnyPublisher<[Repository], Never>
    }

    struct Input {
        let fetchRepositories: () -> Void
        let selectedIndexPath: (IndexPath) -> Void
        let isReachedBottom: (Bool) -> Void
        let headerFooterView: (UIView) -> Void
        let favorites: ([Repository]) -> Void
    }
}
