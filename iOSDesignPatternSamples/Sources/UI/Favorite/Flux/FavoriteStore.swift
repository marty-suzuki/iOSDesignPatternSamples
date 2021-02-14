//
//  FavoriteStore.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import GithubKit

protocol FavoriteStoreType: AnyObject {
    var favorites: [Repository] { get }
    var reloadData: AnyPublisher<Void, Never> { get }
    var selectedRepository: AnyPublisher<Repository, Never> { get }
}

final class FavoriteStore: FavoriteStoreType {
    @Published
    private(set) var favorites: [Repository] = []

    let reloadData: AnyPublisher<Void, Never>
    let selectedRepository: AnyPublisher<Repository, Never>

    private var cancellable = Set<AnyCancellable>()

    init(
        dispatcher: FavoriteDispatcher
    ) {
        let reloadData = PassthroughSubject<Void, Never>()

        self.reloadData = reloadData
            .eraseToAnyPublisher()

        self.selectedRepository = dispatcher.selectedRepository
            .eraseToAnyPublisher()

        dispatcher.favorites
            .assign(to: \.favorites, on: self)
            .store(in: &cancellable)

        $favorites
            .map { _ in }
            .sink(receiveValue: reloadData.send)
            .store(in: &cancellable)
    }
}
