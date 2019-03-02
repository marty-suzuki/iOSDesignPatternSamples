//
//  FavoriteViewModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit
import RxSwift
import RxCocoa

final class FavoriteViewModel {
    let output: Output
    let input: Input

    var favorites: [Repository] {
        return _favorites.value
    }

    private let _favorites = BehaviorRelay<[Repository]>(value: [])
    private let disposeBag = DisposeBag()

    init(favoritesInput: AnyObserver<[Repository]>,
         favoritesOutput: Observable<[Repository]>) {

        let _selectedIndexPath = PublishRelay<IndexPath>()
        let selectedRepository = _selectedIndexPath
            .withLatestFrom(favoritesOutput) { $1[$0.row] }

        self.output = Output(favorites: favoritesOutput,
                             relaodData: favoritesOutput.map { _ in },
                             selectedRepository: selectedRepository)

        self.input = Input(selectedIndexPath: _selectedIndexPath.asObserver(),
                           favorites: favoritesInput)

        favoritesOutput
            .bind(to: _favorites)
            .disposed(by: disposeBag)
    }
}

extension FavoriteViewModel {
    struct Output {
        let favorites: Observable<[Repository]>
        let relaodData: Observable<Void>
        let selectedRepository: Observable<Repository>
    }

    struct Input {
        let selectedIndexPath: AnyObserver<IndexPath>
        let favorites: AnyObserver<[Repository]>
    }
}
