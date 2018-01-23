//
//  Dispatcher.Repository.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import FluxCapacitor
import GithubKit

extension Dispatcher {
    enum Repository: DispatchValue {
        typealias RelatedStoreType = RepositoryStore
        typealias RelatedActionType = RepositoryAction

        case isRepositoryFetching(Bool)
        case addRepositories([GithubKit.Repository])
        case removeAllRepositories
        case selectedRepository(GithubKit.Repository?)
        case lastPageInfo(PageInfo?)
        case repositoryTotalCount(Int)
        
        case addFavorite(GithubKit.Repository)
        case removeFavorite(GithubKit.Repository)
        case removeAllFavorites
    }
}
