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
import RxCocoa

final class UserStore: Storable {
    typealias DispatchValueType = Dispatcher.User
    
    let isUserFetching: Observable<Bool>
    fileprivate let _isUserFetching = BehaviorRelay<Bool>(value: false)
    
    let users: Observable<[User]>
    fileprivate let _users = BehaviorRelay<[User]>(value: [])
    
    let selectedUser: Observable<User?>
    fileprivate let _selectedUser = BehaviorRelay<User?>(value: nil)
    
    let lastPageInfo: Observable<PageInfo?>
    fileprivate let _lastPageInfo = BehaviorRelay<PageInfo?>(value: nil)
    
    let lastSearchQuery: Observable<String>
    fileprivate let _lastSearchQuery = BehaviorRelay<String>(value: "")
    
    let userTotalCount: Observable<Int>
    fileprivate let _userTotalCount = BehaviorRelay<Int>(value: 0)

    let fetchError: Observable<Error>
    private let _fetchError = PublishRelay<Error>()
    
    init(dispatcher: Dispatcher) {
        self.isUserFetching = _isUserFetching.asObservable()
        self.users = _users.asObservable()
        self.selectedUser = _selectedUser.asObservable()
        self.lastPageInfo = _lastPageInfo.asObservable()
        self.lastSearchQuery = _lastSearchQuery.asObservable()
        self.userTotalCount = _userTotalCount.asObservable()
        self.fetchError = _fetchError.asObservable()
        
        register { [weak self] in
            guard let me = self else { return }
            switch $0 {
            case .isUserFetching(let value):
                me._isUserFetching.accept(value)
            case .addUsers(let value):
                me._users.accept(me._users.value + value)
            case .removeAllUsers:
                me._users.accept([])
            case .selectedUser(let value):
                me._selectedUser.accept(value)
            case .lastPageInfo(let value):
                me._lastPageInfo.accept(value)
            case .lastSearchQuery(let value):
                me._lastSearchQuery.accept(value)
            case .userTotalCount(let value):
                me._userTotalCount.accept(value)
            case .fetchError(let value):
                me._fetchError.accept(value)
            }
        }
    }
}

extension UserStore: ValueCompatible {}

extension Value where Base == UserStore {
    var isUserFetching: Bool {
        return base._isUserFetching.value
    }

    var users: [User] {
        return base._users.value
    }

    var selectedUse: User? {
        return base._selectedUser.value
    }

    var lastPageInfo: PageInfo? {
        return base._lastPageInfo.value
    }

    var lastSearchQuery: String {
        return base._lastSearchQuery.value
    }

    var userTotalCount: Int {
        return base._userTotalCount.value
    }
}
