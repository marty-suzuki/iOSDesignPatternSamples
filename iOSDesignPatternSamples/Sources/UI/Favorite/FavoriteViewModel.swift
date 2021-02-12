//
//  FavoriteViewModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import Foundation
import GithubKit

final class FavoriteViewModel {
    let output: Output
    let input: Input

    @Published
    private(set )var favorites: [Repository] = []

    private var cancellable = Set<AnyCancellable>()

    init(
        favoritesInput: @escaping ([Repository]) -> Void,
        favoritesOutput: AnyPublisher<[Repository], Never>
    ) {
        let _selectedIndexPath = PassthroughSubject<IndexPath, Never>()
        let _selectedRepository = PassthroughSubject<Repository, Never>()


        self.output = Output(favorites: favoritesOutput,
                             relaodData: favoritesOutput.map { _ in }.eraseToAnyPublisher(),
                             selectedRepository: _selectedRepository.eraseToAnyPublisher())

        self.input = Input(selectedIndexPath: _selectedIndexPath.send,
                           favorites: favoritesInput)
    _selectedIndexPath
        .flatMap { [weak self] indexPath -> AnyPublisher<Repository, Never> in
            guard let me = self else {
                return Empty().eraseToAnyPublisher()
            }
            return Just(me.favorites[indexPath.row])
                .eraseToAnyPublisher()
        }
        .sink {
            _selectedRepository.send($0)
        }
        .store(in: &cancellable)


        favoritesOutput
            .assign(to: \.favorites, on: self)
            .store(in: &cancellable)
    }
}

extension FavoriteViewModel {
    struct Output {
        let favorites: AnyPublisher<[Repository], Never>
        let relaodData: AnyPublisher<Void, Never>
        let selectedRepository: AnyPublisher<Repository, Never>
    }

    struct Input {
        let selectedIndexPath: (IndexPath) -> Void
        let favorites: ([Repository]) -> Void
    }
}
