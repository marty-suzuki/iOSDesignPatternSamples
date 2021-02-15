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

protocol FavoriteViewModelType: AnyObject {
    var output: FavoriteViewModel.Output { get }
    var input: FavoriteViewModel.Input { get }
}

final class FavoriteViewModel: FavoriteViewModelType {
    let output: Output
    let input: Input

    var favorites: [Repository] {
        favoriteModel.favorites
    }

    private let favoriteModel: FavoriteModelType
    private var cancellable = Set<AnyCancellable>()

    init(
        favoriteModel: FavoriteModelType
    ) {
        self.favoriteModel = favoriteModel
        let _selectedIndexPath = PassthroughSubject<IndexPath, Never>()
        let _selectedRepository = PassthroughSubject<Repository, Never>()
        
        self.output = Output(
            favorites: favoriteModel.favorites,
            relaodData: favoriteModel.favoritePublisher.map { _ in }.eraseToAnyPublisher(),
            selectedRepository: _selectedRepository.eraseToAnyPublisher()
        )

        self.input = Input(selectedIndexPath: _selectedIndexPath.send)

        _selectedIndexPath
            .map { favoriteModel.favorites[$0.row] }
            .sink {
                _selectedRepository.send($0)
            }
            .store(in: &cancellable)

        favoriteModel.favoritePublisher
            .assign(to: \.favorites, on: output)
            .store(in: &cancellable)
    }
}

extension FavoriteViewModel {
    struct Input {
        let selectedIndexPath: (IndexPath) -> Void
    }

    final class Output {
        @Published
        fileprivate(set) var favorites: [Repository]
        let relaodData: AnyPublisher<Void, Never>
        let selectedRepository: AnyPublisher<Repository, Never>
        init(
            favorites: [Repository],
            relaodData: AnyPublisher<Void, Never>,
            selectedRepository: AnyPublisher<Repository, Never>
        ) {
            self.favorites = favorites
            self.relaodData = relaodData
            self.selectedRepository = selectedRepository
        }
    }
}
