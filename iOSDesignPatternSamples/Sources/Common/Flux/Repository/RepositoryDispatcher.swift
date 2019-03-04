//
//  RepositoryDispatcher.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import GithubKit
import RxCocoa
import RxSwift

final class RepositoryDispatcher {
    let isRepositoryFetching = PublishRelay<Bool>()
    let addRepositories = PublishRelay<[GithubKit.Repository]>()
    let removeAllRepositories = PublishRelay<Void>()
    let selectedRepository = PublishRelay<GithubKit.Repository?>()
    let lastPageInfo = PublishRelay<PageInfo?>()
    let repositoryTotalCount = PublishRelay<Int>()
    let addFavorite = PublishRelay<GithubKit.Repository>()
    let removeFavorite = PublishRelay<GithubKit.Repository>()
    let removeAllFavorites = PublishRelay<Void>()
}
