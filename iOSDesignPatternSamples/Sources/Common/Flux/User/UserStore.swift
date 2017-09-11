//
//  UserStore.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import FluxCapacitor
import GithubKit
import RxSwift

final class UserStore: Storable {
    typealias DispatchValueType = Dispatcher.User
    
    let isUserFetching: Observable<Bool>
    var isUserFetchingValue: Bool {
        return _isUserFetching.value
    }
    private let _isUserFetching = Variable<Bool>(false)
    
    let users: Observable<[User]>
    var usersValue: [User] {
        return _users.value
    }
    private let _users = Variable<[User]>([])
    
    let selectedUser: Observable<User?>
    var selectedUserValue: User? {
        return _selectedUser.value
    }
    private let _selectedUser = Variable<User?>(nil)
    
    let lastPageInfo: Observable<PageInfo?>
    var lastPageInfoValue: PageInfo? {
        return _lastPageInfo.value
    }
    private let _lastPageInfo = Variable<PageInfo?>(nil)
    
    let lastSearchQuery: Observable<String>
    var lastSearchQueryValue: String {
        return _lastSearchQuery.value
    }
    private let _lastSearchQuery = Variable<String>("")
    
    let userTotalCount: Observable<Int>
    var userTotalCountValue: Int {
        return _userTotalCount.value
    }
    private let _userTotalCount = Variable<Int>(0)
    
    init(dispatcher: Dispatcher) {
        self.isUserFetching = _isUserFetching.asObservable()
        self.users = _users.asObservable()
        self.selectedUser = _selectedUser.asObservable()
        self.lastPageInfo = _lastPageInfo.asObservable()
        self.lastSearchQuery = _lastSearchQuery.asObservable()
        self.userTotalCount = _userTotalCount.asObservable()
        
        register { [weak self] in
            switch $0 {
            case .isUserFetching(let value):
                self?._isUserFetching.value = value
            case .addUsers(let value):
                self?._users.value.append(contentsOf: value)
            case .removeAllUsers:
                self?._users.value.removeAll()
            case .selectedUser(let value):
                self?._selectedUser.value = value
            case .lastPageInfo(let value):
                self?._lastPageInfo.value = value
            case .lastSearchQuery(let value):
                self?._lastSearchQuery.value = value
            case .userTotalCount(let value):
                self?._userTotalCount.value = value
            }
        }
    }
}
