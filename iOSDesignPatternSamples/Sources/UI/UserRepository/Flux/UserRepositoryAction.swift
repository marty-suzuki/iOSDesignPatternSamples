//
//  UserRepositoryAction.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import Foundation
import GithubKit
import UIKit

protocol UserRepositoryActionType: AnyObject {
    func select(
        from repositories: [Repository],
        at indexPath: IndexPath
    )
    func fetchRepositories()
    func isReachedBottom(_ isReachedBottom: Bool)
    func headerFooterView(_ view: UIView)
    func load()
}

final class UserRepositoryAction: UserRepositoryActionType {
    private let dispatcher: UserRepositoryDispatcher
    private let repositoryModel: RepositoryModelType

    private let _isReachedBottom = PassthroughSubject<Bool, Never>()
    private let _headerFooterView = PassthroughSubject<UIView, Never>()
    private let _load = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(
        dispatcher: UserRepositoryDispatcher,
        repositoryModel: RepositoryModelType
    ) {
        self.dispatcher = dispatcher
        self.repositoryModel = repositoryModel

        _isReachedBottom
              .removeDuplicates()
              .filter { $0 }
              .sink { _ in
                  repositoryModel.fetchRepositories()
              }
              .store(in: &cancellables)

        _headerFooterView
            .combineLatest(repositoryModel.isFetchingRepositoriesPublisher)
            .sink(receiveValue: dispatcher.updateLoadingView.send)
            .store(in: &cancellables)

        _load
            .map {
                repositoryModel.totalCountPublisher
                    .combineLatest(repositoryModel.repositoriesPublisher)
            }
            .switchToLatest()
            .map { "\($1.count) / \($0)" }
            .sink(receiveValue: dispatcher.countString.send)
            .store(in: &cancellables)

        _load
            .map { repositoryModel.isFetchingRepositoriesPublisher }
            .switchToLatest()
            .sink(receiveValue: dispatcher.isRepositoryFetching.send)
            .store(in: &cancellables)

        _load
            .map { repositoryModel.repositoriesPublisher }
            .switchToLatest()
            .sink(receiveValue: dispatcher.repositories.send)
            .store(in: &cancellables)
    }

    func select(
        from repositories: [Repository],
        at indexPath: IndexPath
    ) {
        let repository = repositories[indexPath.row]
        dispatcher.selectedRepository.send(repository)
    }

    func fetchRepositories() {
        repositoryModel.fetchRepositories()
    }

    func isReachedBottom(_ isReachedBottom: Bool) {
        _isReachedBottom.send(isReachedBottom)
    }

    func headerFooterView(_ view: UIView) {
        _headerFooterView.send(view)
    }

    func load() {
        _load.send()
    }
}
