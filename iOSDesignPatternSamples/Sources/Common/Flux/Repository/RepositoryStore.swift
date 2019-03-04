//
//  RepositoryStore.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import GithubKit
import RxSwift
import RxCocoa

final class RepositoryStore {
    let isRepositoryFetching: Observable<Bool>
    fileprivate let _isRepositoryFetching = BehaviorRelay<Bool>(value: false)
    
    let favorites: Observable<[Repository]>
    fileprivate let _favorites = BehaviorRelay<[Repository]>(value: [])
    
    let repositories: Observable<[Repository]>
    fileprivate let _repositories = BehaviorRelay<[Repository]>(value: [])
    
    let selectedRepository: Observable<Repository?>
    fileprivate let _selectedRepository = BehaviorRelay<Repository?>(value: nil)
    
    let lastPageInfo: Observable<PageInfo?>
    fileprivate let _lastPageInfo = BehaviorRelay<PageInfo?>(value: nil)
    
    let repositoryTotalCount: Observable<Int>
    fileprivate let _repositoryTotalCount = BehaviorRelay<Int>(value: 0)

    private let disposeBag = DisposeBag()

    init(dispatcher: RepositoryDispatcher) {
        self.isRepositoryFetching = _isRepositoryFetching.asObservable()
        self.favorites = _favorites.asObservable()
        self.repositories = _repositories.asObservable()
        self.selectedRepository = _selectedRepository.asObservable()
        self.lastPageInfo = _lastPageInfo.asObservable()
        self.repositoryTotalCount = _repositoryTotalCount.asObservable()

        dispatcher.isRepositoryFetching
            .bind(to: _isRepositoryFetching)
            .disposed(by: disposeBag)

        dispatcher.addRepositories
            .withLatestFrom(_repositories) { $1 + $0 }
            .bind(to: _repositories)
            .disposed(by: disposeBag)

        dispatcher.removeAllRepositories
            .map { [] }
            .bind(to: _repositories)
            .disposed(by: disposeBag)

        dispatcher.selectedRepository
            .bind(to: _selectedRepository)
            .disposed(by: disposeBag)

        dispatcher.lastPageInfo
            .bind(to: _lastPageInfo)
            .disposed(by: disposeBag)

        dispatcher.repositoryTotalCount
            .bind(to: _repositoryTotalCount)
            .disposed(by: disposeBag)

        dispatcher.addFavorite
            .withLatestFrom(_favorites) { $1 + [$0] }
            .bind(to: _favorites)
            .disposed(by: disposeBag)

        dispatcher.removeFavorite
            .withLatestFrom(_favorites) { ($0, $1) }
            .map { repository, favorites in
                favorites.filter { $0.url != repository.url }
            }
            .bind(to: _favorites)
            .disposed(by: disposeBag)

        dispatcher.removeAllFavorites
            .map { [] }
            .bind(to: _favorites)
            .disposed(by: disposeBag)
    }
}

extension RepositoryStore: ValueCompatible {}

extension Value where Base == RepositoryStore {
    var isRepositoryFetching: Bool {
        return base._isRepositoryFetching.value
    }

    var favorites: [Repository] {
        return base._favorites.value
    }

    var repositories: [Repository] {
        return base._repositories.value
    }

    var selectedRepository: Repository? {
        return base._selectedRepository.value
    }

    var lastPageInfo: PageInfo? {
        return base._lastPageInfo.value
    }

    var repositoryTotalCount: Int {
        return base._repositoryTotalCount.value
    }
}
