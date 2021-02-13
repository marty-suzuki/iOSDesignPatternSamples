//
//  RepositoryDispatcher.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit

final class RepositoryDispatcher {
    let isRepositoryFetching = PassthroughSubject<Bool, Never>()
    let addRepositories = PassthroughSubject<[GithubKit.Repository], Never>()
    let removeAllRepositories = PassthroughSubject<Void, Never>()
    let selectedRepository = PassthroughSubject<GithubKit.Repository?, Never>()
    let lastPageInfo = PassthroughSubject<PageInfo?, Never>()
    let repositoryTotalCount = PassthroughSubject<Int, Never>()
    let addFavorite = PassthroughSubject<GithubKit.Repository, Never>()
    let removeFavorite = PassthroughSubject<GithubKit.Repository, Never>()
    let removeAllFavorites = PassthroughSubject<Void, Never>()
}
