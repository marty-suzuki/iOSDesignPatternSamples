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
    
    init() {
        self.isUserFetching = _isUserFetching.asObservable()
        self.users = _users.asObservable()
        self.selectedUser = _selectedUser.asObservable()
        self.lastPageInfo = _lastPageInfo.asObservable()
        self.lastSearchQuery = _lastSearchQuery.asObservable()
        self.userTotalCount = _userTotalCount.asObservable()
        self.fetchError = _fetchError.asObservable()
    }

    func reduce(with state: Dispatcher.User) {
        switch state {
        case .isUserFetching(let value):
            _isUserFetching.accept(value)
        case .addUsers(let value):
            _users.accept(_users.value + value)
        case .removeAllUsers:
            _users.accept([])
        case .selectedUser(let value):
            _selectedUser.accept(value)
        case .lastPageInfo(let value):
            _lastPageInfo.accept(value)
        case .lastSearchQuery(let value):
            _lastSearchQuery.accept(value)
        case .userTotalCount(let value):
            _userTotalCount.accept(value)
        case .fetchError(let value):
            _fetchError.accept(value)
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
