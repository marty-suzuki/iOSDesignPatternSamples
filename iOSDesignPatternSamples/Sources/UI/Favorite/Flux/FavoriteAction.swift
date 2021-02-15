//
//  FavoriteAction.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import Foundation
import GithubKit

protocol FavoriteActionType: AnyObject {
    func select(
        from repositories: [Repository],
        for indexPath: IndexPath
    )
    func load()
}

final class FavoriteAction: FavoriteActionType {
    private let _load = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let dispatcher: FavoriteDispatcher

    init(
        dispatcher: FavoriteDispatcher,
        favoriteModel: FavoriteModelType
    ) {
        self.dispatcher = dispatcher

        _load
            .map { favoriteModel.favoritePublisher }
            .switchToLatest()
            .sink(receiveValue: dispatcher.favorites.send)
            .store(in: &cancellables)
    }

    func select(
        from repositories: [Repository],
        for indexPath: IndexPath
    ) {
        let repository = repositories[indexPath.row]
        dispatcher.selectedRepository.send(repository)
    }

    func load() {
        _load.send()
    }
}
