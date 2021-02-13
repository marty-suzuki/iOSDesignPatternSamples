//
//  UserStore.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import Foundation
import GithubKit

final class UserStore {
    @Published
    private(set) var isUserFetching = false

    @Published
    private(set) var users: [User] = []

    @Published
    private(set) var selectedUser: User?

    @Published
    private(set) var lastPageInfo: PageInfo?

    @Published
    private(set) var lastSearchQuery = ""

    @Published
    private(set) var userTotalCount: Int = 0

    let fetchError: AnyPublisher<ErrorMessage, Never>

    private var cancellables = Set<AnyCancellable>()

    init(dispatcher: UserDispatcher) {
        self.fetchError = dispatcher.fetchError.eraseToAnyPublisher()

        dispatcher.isUserFetching
            .assign(to: \.isUserFetching, on: self)
            .store(in: &cancellables)

        dispatcher.addUsers
            .map { [weak self] users in
                self.map { $0.users + users } ?? []
            }
            .assign(to: \.users, on: self)
            .store(in: &cancellables)

        dispatcher.removeAllUsers
            .map { [] }
            .assign(to: \.users, on: self)
            .store(in: &cancellables)

        dispatcher.selectedUser
            .assign(to: \.selectedUser, on: self)
            .store(in: &cancellables)

        dispatcher.lastPageInfo
            .assign(to: \.lastPageInfo, on: self)
            .store(in: &cancellables)

        dispatcher.lastSearchQuery
            .assign(to: \.lastSearchQuery, on: self)
            .store(in: &cancellables)

        dispatcher.userTotalCount
            .assign(to: \.userTotalCount, on: self)
            .store(in: &cancellables)
    }
}
