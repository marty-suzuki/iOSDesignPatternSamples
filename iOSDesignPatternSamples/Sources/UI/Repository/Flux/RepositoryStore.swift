//
//  RepositoryStore.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import Foundation
import GithubKit

protocol RepositoryStoreType: AnyObject {
    var repository: Repository { get }
    var favoriteButtonTitlePublisher: Published<String>.Publisher { get }
}

final class RepositoryStore: RepositoryStoreType {
    let repository: Repository

    @Published
    private(set) var favoriteButtonTitle = ""
    var favoriteButtonTitlePublisher: Published<String>.Publisher {
        $favoriteButtonTitle
    }

    private var cancellables = Set<AnyCancellable>()

    init(
        repository: Repository,
        dispatcher: RepositoryDispatcher
    ) {
        self.repository = repository

        dispatcher.favoriteButtonTitle
            .assign(to: \.favoriteButtonTitle, on: self)
            .store(in: &cancellables)
    }
}
