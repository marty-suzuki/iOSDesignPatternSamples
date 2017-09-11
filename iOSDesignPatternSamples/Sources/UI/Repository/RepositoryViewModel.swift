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
    let favoriteButtonTitle: Observable<String>
    private let disposeBag = DisposeBag()

    init(repository: Repository,
         favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>,
         favoriteButtonTap: ControlEvent<Void>) {
        let favoritesAndIndex = favoritesOutput
            .map { [repository] favorites in
                (favorites, favorites.index(where: { $0.url == repository.url }))
            }

        self.favoriteButtonTitle = favoritesAndIndex
            .map { $0.1 == nil ? "Add" : "Remove" }

        favoriteButtonTap
            .withLatestFrom(favoritesAndIndex)
            .map { [repository] favorites, index in
                var favorites = favorites
                if let index = index {
                    favorites.remove(at: index)
                    return favorites
                }
                favorites.append(repository)
                return favorites
            }
            // to use "onNext" because to avoid sending dispose
            .subscribe(onNext: { favoritesInput.onNext($0) })
            .disposed(by: disposeBag)
    }
}
