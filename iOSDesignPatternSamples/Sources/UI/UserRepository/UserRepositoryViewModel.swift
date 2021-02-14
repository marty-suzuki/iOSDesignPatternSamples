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

protocol UserRepositoryViewModelType: AnyObject {
    var input: UserRepositoryViewModel.Input { get }
    var output: UserRepositoryViewModel.Output { get }
}

final class UserRepositoryViewModel: UserRepositoryViewModelType {
    let input: Input
    let output: Output

    private var cancellables = Set<AnyCancellable>()

    init(
        user: User,
        favoriteModel: FavoriteModelType,
        repositoryModel: RepositoryModelType
    ) {
        let _fetchRepositories = PassthroughSubject<Void, Never>()
        let _selectedIndexPath = PassthroughSubject<IndexPath, Never>()
        let _isReachedBottom = PassthroughSubject<Bool, Never>()
        let _headerFooterView = PassthroughSubject<UIView, Never>()

        self.input = Input(
            fetchRepositories: _fetchRepositories.send,
            selectedIndexPath: _selectedIndexPath.send,
            isReachedBottom: _isReachedBottom.send,
            headerFooterView: _headerFooterView.send
        )

        do {
            let updateLoadingView = _headerFooterView
                .combineLatest(repositoryModel.isFetchingRepositoriesPublisher)
                .eraseToAnyPublisher()

            let showRepository = _selectedIndexPath
                .map { repositoryModel.repositories[$0.row] }
                .eraseToAnyPublisher()

            let countString = repositoryModel.totalCountPublisher
                .combineLatest(repositoryModel.repositoriesPublisher)
                .map { "\($1.count) / \($0)" }
                .eraseToAnyPublisher()

            let reloadData = repositoryModel.repositoriesPublisher.map { _ in }
                .merge(with: repositoryModel.totalCountPublisher.map { _ in },
                       repositoryModel.isFetchingRepositoriesPublisher.map { _ in })
                .eraseToAnyPublisher()

            self.output = Output(
                title: "\(user.login)'s Repositories",
                repositories: repositoryModel.repositories,
                isFetchingRepositories: repositoryModel.isFetchingRepositories,
                updateLoadingView: updateLoadingView,
                showRepository: showRepository,
                countString: countString,
                reloadData: reloadData
            )
        }

        _isReachedBottom
            .removeDuplicates()
            .filter { $0 }
            .sink { _ in
                repositoryModel.fetchRepositories()
            }
            .store(in: &cancellables)

        repositoryModel.repositoriesPublisher
            .assign(to: \.repositories, on: output)
            .store(in: &cancellables)

        repositoryModel.isFetchingRepositoriesPublisher
            .assign(to: \.isFetchingRepositories, on: output)
            .store(in: &cancellables)

        repositoryModel.fetchRepositories()
    }
}

extension UserRepositoryViewModel {
    struct Input {
        let fetchRepositories: () -> Void
        let selectedIndexPath: (IndexPath) -> Void
        let isReachedBottom: (Bool) -> Void
        let headerFooterView: (UIView) -> Void
    }

    final class Output {
        @Published
        fileprivate(set) var title: String
        @Published
        fileprivate(set) var repositories: [Repository]
        @Published
        fileprivate(set) var isFetchingRepositories: Bool
        let updateLoadingView: AnyPublisher<(UIView, Bool), Never>
        let showRepository: AnyPublisher<Repository, Never>
        let countString: AnyPublisher<String, Never>
        let reloadData: AnyPublisher<Void, Never>
        init(
            title: String,
            repositories: [Repository],
            isFetchingRepositories: Bool,
            updateLoadingView: AnyPublisher<(UIView, Bool), Never>,
            showRepository: AnyPublisher<Repository, Never>,
            countString: AnyPublisher<String, Never>,
            reloadData: AnyPublisher<Void, Never>
        ) {
            self.title = title
            self.repositories = repositories
            self.isFetchingRepositories = isFetchingRepositories
            self.updateLoadingView = updateLoadingView
            self.showRepository = showRepository
            self.countString = countString
            self.reloadData = reloadData
        }
    }
}
