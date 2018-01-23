//
//  Dispatcher.User.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import FluxCapacitor
import GithubKit

extension Dispatcher {
    enum User: DispatchValue {
        typealias RelatedStoreType = UserStore
        typealias RelatedActionType = UserAction

        case isUserFetching(Bool)
        case addUsers([GithubKit.User])
        case userTotalCount(Int)
        case removeAllUsers
        case selectedUser(GithubKit.User?)
        case lastPageInfo(PageInfo?)
        case lastSearchQuery(String)
        case fetchError(Error)
    }
}
