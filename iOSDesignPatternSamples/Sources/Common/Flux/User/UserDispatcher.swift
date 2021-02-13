//
//  UserDispatcher.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit

final class UserDispatcher {
    let isUserFetching = PassthroughSubject<Bool, Never>()
    let addUsers = PassthroughSubject<[GithubKit.User], Never>()
    let userTotalCount = PassthroughSubject<Int, Never>()
    let removeAllUsers = PassthroughSubject<Void, Never>()
    let selectedUser = PassthroughSubject<GithubKit.User?, Never>()
    let lastPageInfo = PassthroughSubject<PageInfo?, Never>()
    let lastSearchQuery = PassthroughSubject<String, Never>()
    let fetchError = PassthroughSubject<ErrorMessage, Never>()
}
