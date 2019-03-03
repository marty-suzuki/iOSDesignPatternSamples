//
//  FavoriteModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/28.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import GithubKit
import RxSwift
import RxCocoa

final class FavoriteModel {

    let contains: Observable<(Bool, Repository)>

    private let _addFavorite = PublishRelay<Repository>()
    private let _removeFavorite = PublishRelay<Repository>()

    private let disposeBag = DisposeBag()

    init(repository: Repository,
         favoritesInput: AnyObserver<[Repository]>,
         favoritesOutput: Observable<[Repository]>) {

        self.contains = favoritesOutput
            .map { favorites in
                (favorites.contains { $0.url == repository.url }, repository)
            }
            .share(replay: 1, scope: .whileConnected)

        do {
            let favorites1 = _addFavorite
                .withLatestFrom(favoritesOutput) { ($0, $1) }
                .flatMap { repository, favorites -> Observable<[Repository]> in
                    var favorites = favorites
                    if favorites.lazy.index(where: { $0.url == repository.url }) != nil {
                        return .empty()
                    }
                    favorites.append(repository)
                    return .just(favorites)
                }

            let favorites2 = _removeFavorite
                .withLatestFrom(favoritesOutput) { ($0, $1) }
                .flatMap { repository, favorites -> Observable<[Repository]> in
                    var favorites = favorites
                    guard let index = favorites.lazy.index(where: { $0.url == repository.url }) else {
                        return .empty()
                    }
                    favorites.remove(at: index)
                    return .just(favorites)
                }

            Observable.merge(favorites1, favorites2)
                // to use ".concat(Observable.never())" because to avoid sending dispose
                .concat(Observable.never())
                .bind(to: favoritesInput)
                .disposed(by: disposeBag)
        }
    }

    func addFavorite(_ repository: Repository) {
        _addFavorite.accept(repository)
    }
    
    func removeFavorite(_ repository: Repository) {
        _removeFavorite.accept(repository)
    }
}
