//
//  RepositoryViewModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/11.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit
import RxSwift
import RxCocoa

final class RepositoryViewModel {
    let output: Output
    let input: Input

    private let disposeBag = DisposeBag()

    init(repository: Repository,
         favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>) {

        let model = FavoriteModel(repository: repository,
                                  favoritesInput: favoritesInput,
                                  favoritesOutput: favoritesOutput)

        do {
            let favoriteButtonTitle = model.contains
                .map { $0.0 ? "Remove" : "Add" }
                .share(replay: 1, scope: .whileConnected)

            self.output = Output(favoriteButtonTitle: favoriteButtonTitle)
        }

        let favoriteButtonTap = PublishRelay<Void>()
        self.input = Input(favoriteButtonTap: favoriteButtonTap.asObserver())

        favoriteButtonTap
            .withLatestFrom(model.contains)
            .subscribe(onNext: { contains, repository in
                if contains {
                    model.removeFavorite(repository)
                } else {
                    model.addFavorite(repository)
                }
            })
            .disposed(by: disposeBag)
    }
}

extension RepositoryViewModel {
    struct Output {
        let favoriteButtonTitle: Observable<String>
    }

    struct Input {
        let favoriteButtonTap: AnyObserver<Void>
    }
}
