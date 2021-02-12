//
//  RepositoryViewModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/11.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import Foundation
import GithubKit

final class RepositoryViewModel {
    let output: Output
    let input: Input

    private var cancellables = Set<AnyCancellable>()

    init(
        repository: Repository,
        favoritesOutput: AnyPublisher<[Repository], Never>,
        favoritesInput: @escaping ([Repository]) -> Void
    ) {
        let model = FavoriteModel(repository: repository,
                                  favoritesInput: favoritesInput,
                                  favoritesOutput: favoritesOutput)

        do {
            let favoriteButtonTitle = model.contains
                .map { $0.0 ? "Remove" : "Add" }
                .eraseToAnyPublisher()

            self.output = Output(favoriteButtonTitle: favoriteButtonTitle)
        }

        let favoriteButtonTap = PassthroughSubject<Void, Never>()
        self.input = Input(favoriteButtonTap: favoriteButtonTap.send)

        favoriteButtonTap
            .flatMap { _ in
                model.contains
            }
            .sink { contains, repository in
                if contains {
                    model.removeFavorite(repository)
                } else {
                    model.addFavorite(repository)
                }
            }
            .store(in: &cancellables)
    }
}

extension RepositoryViewModel {
    struct Output {
        let favoriteButtonTitle: AnyPublisher<String, Never>
    }

    struct Input {
        let favoriteButtonTap: () -> Void
    }
}
