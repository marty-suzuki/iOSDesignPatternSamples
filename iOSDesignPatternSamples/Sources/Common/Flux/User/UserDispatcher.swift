//
//  UserDispatcher.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import RxCocoa
import GithubKit

final class UserDispatcher {
    let isUserFetching = PublishRelay<Bool>()
    let addUsers = PublishRelay<[GithubKit.User]>()
    let userTotalCount = PublishRelay<Int>()
    let removeAllUsers = PublishRelay<Void>()
    let selectedUser = PublishRelay<GithubKit.User?>()
    let lastPageInfo = PublishRelay<PageInfo?>()
    let lastSearchQuery = PublishRelay<String>()
    let fetchError = PublishRelay<ErrorMessage>()
}
