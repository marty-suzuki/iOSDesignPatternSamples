//
//  UserAction.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import GithubKit
import RxCocoa
import RxSwift

final class UserAction {

    private let model: SearchModel
    private let dispatcher: UserDispatcher
    private let disposeBag = DisposeBag()

    init(dispatcher: UserDispatcher,
         model: SearchModel) {
        self.model = model
        self.dispatcher = dispatcher

        model.response
            .subscribe(onNext: {
                dispatcher.addUsers.accept($0.nodes)
                dispatcher.lastPageInfo.accept($0.pageInfo)
                dispatcher.userTotalCount.accept($0.totalCount)
            })
            .disposed(by: disposeBag)

        model.errorMessage
            .subscribe(onNext: {
                dispatcher.fetchError.accept($0)
            })
            .disposed(by: disposeBag)

        model.isFetchingUsers
            .subscribe(onNext: {
                dispatcher.isUserFetching.accept($0)
            })
            .disposed(by: disposeBag)
    }
    
    func fetchUsers(withQuery query: String, after: String?) {
        dispatcher.lastSearchQuery.accept(query)
        guard !query.isEmpty else {
            return
        }
        model.fetchUsers(withQuery: query, after: after)
    }

    func selectUser(_ user: User) {
        dispatcher.selectedUser.accept(user)
    }

    func clearSelectedUser() {
        dispatcher.selectedUser.accept(nil)
    }

    func addUsers(_ users: [User]) {
        dispatcher.addUsers.accept(users)
    }

    func removeAllUsers() {
        dispatcher.removeAllUsers.accept(())
    }

    func pageInfo(_ pageInfo: PageInfo) {
        dispatcher.lastPageInfo.accept(pageInfo)
    }

    func clearPageInfo() {
        dispatcher.lastPageInfo.accept(nil)
    }

    func userTotalCount(_ count: Int) {
        dispatcher.userTotalCount.accept(count)
    }

    func isUserFetching(_ isFetching: Bool) {
        dispatcher.isUserFetching.accept(isFetching)
    }
}
