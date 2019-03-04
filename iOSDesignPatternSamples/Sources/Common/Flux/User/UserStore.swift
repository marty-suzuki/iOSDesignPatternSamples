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

final class UserStore {
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

    let fetchError: Observable<ErrorMessage>

    private let disposeBag = DisposeBag()

    init(dispatcher: UserDispatcher) {
        self.isUserFetching = _isUserFetching.asObservable()
        self.users = _users.asObservable()
        self.selectedUser = _selectedUser.asObservable()
        self.lastPageInfo = _lastPageInfo.asObservable()
        self.lastSearchQuery = _lastSearchQuery.asObservable()
        self.userTotalCount = _userTotalCount.asObservable()
        self.fetchError = dispatcher.fetchError.asObservable()

        dispatcher.isUserFetching
            .bind(to: _isUserFetching)
            .disposed(by: disposeBag)

        dispatcher.addUsers
            .withLatestFrom(_users) { $1 + $0 }
            .bind(to: _users)
            .disposed(by: disposeBag)

        dispatcher.removeAllUsers
            .map { [] }
            .bind(to: _users)
            .disposed(by: disposeBag)

        dispatcher.selectedUser
            .bind(to: _selectedUser)
            .disposed(by: disposeBag)

        dispatcher.lastPageInfo
            .bind(to: _lastPageInfo)
            .disposed(by: disposeBag)

        dispatcher.lastSearchQuery
            .bind(to: _lastSearchQuery)
            .disposed(by: disposeBag)

        dispatcher.userTotalCount
            .bind(to: _userTotalCount)
            .disposed(by: disposeBag)
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
