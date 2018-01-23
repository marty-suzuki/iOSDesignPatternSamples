//
//  RepositoryStore.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import FluxCapacitor
import GithubKit
import RxSwift
import RxCocoa

final class RepositoryStore: Storable {
    typealias DispatchValueType = Dispatcher.Repository
    
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
    
    init(dispatcher: Dispatcher) {
        self.isRepositoryFetching = _isRepositoryFetching.asObservable()
        self.favorites = _favorites.asObservable()
        self.repositories = _repositories.asObservable()
        self.selectedRepository = _selectedRepository.asObservable()
        self.lastPageInfo = _lastPageInfo.asObservable()
        self.repositoryTotalCount = _repositoryTotalCount.asObservable()
        
        register { [weak self] in
            guard let me = self else { return }
            switch $0 {
            case .isRepositoryFetching(let value):
                me._isRepositoryFetching.accept(value)
            case .addRepositories(let value):
                me._repositories.accept(me._repositories.value + value)
            case .removeAllRepositories:
                me._repositories.accept([])
            case .selectedRepository(let value):
                me._selectedRepository.accept(value)
            case .lastPageInfo(let value):
                me._lastPageInfo.accept(value)
            case .repositoryTotalCount(let value):
                me._repositoryTotalCount.accept(value)
                
            case .addFavorite(let value):
                if me._favorites.value.index(where: { $0.url == value.url }) == nil {
                    me._favorites.accept(me._favorites.value + [value])
                }
            case .removeFavorite(let value):
                if let index = self?._favorites.value.index(where: { $0.url == value.url }) {
                    var favorites = me._favorites.value
                    favorites.remove(at: index)
                    me._favorites.accept(favorites)
                }
            case .removeAllFavorites:
                me._favorites.accept([])
            }
        }
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
