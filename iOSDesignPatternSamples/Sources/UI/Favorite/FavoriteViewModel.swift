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
    let favorites: Observable<[Repository]>
    let relaodData: Observable<Void>
    let selectedRepository: Observable<Repository>

    fileprivate let _favorites = BehaviorRelay<[Repository]>(value: [])
    private let disposeBag = DisposeBag()

    init(favoritesObservable: Observable<[Repository]>,
         selectedIndexPath: Observable<IndexPath>) {
        self.favorites = _favorites.asObservable()
        self.relaodData = _favorites.asObservable().map { _ in }
        self.selectedRepository = selectedIndexPath
            .withLatestFrom(_favorites.asObservable()) { $1[$0.row] }

        favoritesObservable
            .bind(to: _favorites)
            .disposed(by: disposeBag)
    }
}

extension FavoriteViewModel: ValueCompatible {}

extension Value where Base == FavoriteViewModel {
    var favorites: [Repository] {
        return base._favorites.value
    }
}
