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

protocol RepositoryViewModelType: AnyObject {
    var input: RepositoryViewModel.Input { get }
    var output: RepositoryViewModel.Output { get }
}

final class RepositoryViewModel: RepositoryViewModelType {
    let input: Input
    let output: Output

    private var cancellables = Set<AnyCancellable>()

    init(
        repository: Repository,
        favoritesModel: FavoriteModelType
    ) {
        let favoriteButtonTitle = favoritesModel.contains(repository)
            .map { $0 ? "Remove" : "Add" }
            .eraseToAnyPublisher()

        self.output = Output(
            url: repository.url,
            favoriteButtonTitle: favoriteButtonTitle
        )

        let favoriteButtonTap = PassthroughSubject<Void, Never>()
        self.input = Input(favoriteButtonTap: favoriteButtonTap.send)

        favoriteButtonTap
            .map { _ in
                favoritesModel.contains(repository).prefix(1)
            }
            .switchToLatest()
            .sink { contains in
                if contains {
                    favoritesModel.removeFavorite(repository)
                } else {
                    favoritesModel.addFavorite(repository)
                }
            }
            .store(in: &cancellables)
    }
}

extension RepositoryViewModel {
    struct Input {
        let favoriteButtonTap: () -> Void
    }

    final class Output {
        @Published
        fileprivate(set) var url: URL
        let favoriteButtonTitle: AnyPublisher<String, Never>
        init(
            url: URL,
            favoriteButtonTitle: AnyPublisher<String, Never>
        ) {
            self.url = url
            self.favoriteButtonTitle = favoriteButtonTitle
        }
    }
}
