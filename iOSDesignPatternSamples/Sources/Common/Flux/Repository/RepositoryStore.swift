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

final class RepositoryStore: Storable {
    typealias DispatchValueType = Dispatcher.Repository
    
    let isRepositoryFetching: Observable<Bool>
    var isRepositoryFetchingValue: Bool {
        return _isRepositoryFetching.value
    }
    private let _isRepositoryFetching = Variable<Bool>(false)
    
    let favorites: Observable<[Repository]>
    var favoritesValue: [Repository] {
        return _favorites.value
    }
    private let _favorites = Variable<[Repository]>([])
    
    let repositories: Observable<[Repository]>
    var repositoriesValue: [Repository] {
        return _repositories.value
    }
    private let _repositories = Variable<[Repository]>([])
    
    let selectedRepository: Observable<Repository?>
    var selectedRepositoryValue: Repository? {
        return _selectedRepository.value
    }
    private let _selectedRepository = Variable<Repository?>(nil)
    
    let lastPageInfo: Observable<PageInfo?>
    var lastPageInfoValue: PageInfo? {
        return _lastPageInfo.value
    }
    private let _lastPageInfo = Variable<PageInfo?>(nil)
    
    let repositoryTotalCount: Observable<Int>
    var repositoryTotalCountValue: Int {
        return _repositoryTotalCount.value
    }
    private let _repositoryTotalCount = Variable<Int>(0)
    
    init(dispatcher: Dispatcher) {
        self.isRepositoryFetching = _isRepositoryFetching.asObservable()
        self.favorites = _favorites.asObservable()
        self.repositories = _repositories.asObservable()
        self.selectedRepository = _selectedRepository.asObservable()
        self.lastPageInfo = _lastPageInfo.asObservable()
        self.repositoryTotalCount = _repositoryTotalCount.asObservable()
        
        register { [weak self] in
            switch $0 {
            case .isRepositoryFetching(let value):
                self?._isRepositoryFetching.value = value
            case .addRepositories(let value):
                self?._repositories.value.append(contentsOf: value)
            case .removeAllRepositories:
                self?._repositories.value.removeAll()
            case .selectedRepository(let value):
                self?._selectedRepository.value = value
            case .lastPageInfo(let value):
                self?._lastPageInfo.value = value
            case .repositoryTotalCount(let value):
                self?._repositoryTotalCount.value = value
                
            case .addFavorite(let value):
                if self?._favorites.value.index(where: { $0.url == value.url }) == nil {
                    self?._favorites.value.append(value)
                }
            case .removeFavorite(let value):
                if let index = self?._favorites.value.index(where: { $0.url == value.url }) {
                    self?._favorites.value.remove(at: index)
                }
            case .removeAllFavorites:
                self?._favorites.value.removeAll()
            }
        }
    }
}

