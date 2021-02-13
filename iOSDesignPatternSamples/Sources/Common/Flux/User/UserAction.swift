//
//  UserAction.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit

final class UserAction {

    private let searchModel: SearchModelType
    private let dispatcher: UserDispatcher
    private var cancellables = Set<AnyCancellable>()

    init(
        dispatcher: UserDispatcher,
        searchModel: SearchModelType
    ) {
        self.searchModel = searchModel
        self.dispatcher = dispatcher

//        model.response
//            .subscribe(onNext: {
//                dispatcher.addUsers.accept($0.nodes)
//                dispatcher.lastPageInfo.accept($0.pageInfo)
//                dispatcher.userTotalCount.accept($0.totalCount)
//            })
//            .disposed(by: disposeBag)

        searchModel.errorMessage
            .sink {
                dispatcher.fetchError.send($0)
            }
            .store(in: &cancellables)

        searchModel.isFetchingUsersPublisher
            .sink {
                dispatcher.isUserFetching.send($0)
            }
            .store(in: &cancellables)
    }
    
    func fetchUsers(withQuery query: String, after: String?) {
        dispatcher.lastSearchQuery.send(query)
        guard !query.isEmpty else {
            return
        }
        //model.fetchUsers(withQuery: query, after: after)
    }

    func selectUser(_ user: User) {
        dispatcher.selectedUser.send(user)
    }

    func clearSelectedUser() {
        dispatcher.selectedUser.send(nil)
    }

    func addUsers(_ users: [User]) {
        dispatcher.addUsers.send(users)
    }

    func removeAllUsers() {
        dispatcher.removeAllUsers.send()
    }

    func pageInfo(_ pageInfo: PageInfo) {
        dispatcher.lastPageInfo.send(pageInfo)
    }

    func clearPageInfo() {
        dispatcher.lastPageInfo.send(nil)
    }

    func userTotalCount(_ count: Int) {
        dispatcher.userTotalCount.send(count)
    }

    func isUserFetching(_ isFetching: Bool) {
        dispatcher.isUserFetching.send(isFetching)
    }
}
