//
//  SearchModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2019/03/01.
//  Copyright © 2019 marty-suzuki. All rights reserved.
//

import GithubKit
import RxSwift
import RxCocoa

struct ErrorMessage {
    let title: String
    let message: String
}

final class SearchModel {

    let errorMessage: Observable<ErrorMessage>
    let users: Observable<[User]>
    let isFetchingUsers: Observable<Bool>
    let totalCount: Observable<Int>

    var usersValue: [User] {
        return _users.value
    }

    var isFetchingUsersValue: Bool {
        return _isFetchingUsers.value
    }

    private let _users = BehaviorRelay<[User]>(value: [])
    private let _isFetchingUsers = BehaviorRelay<Bool>(value: false)

    private let disposeBag = DisposeBag()

    private let _fetchUsers = PublishRelay<Void>()
    private let _feachUsersWithQuery = PublishRelay<String>()

    init() {
        let _pageInfo = BehaviorRelay<PageInfo?>(value: nil)
        let _totalCount = BehaviorRelay<Int>(value: 0)

        self.totalCount = _totalCount.asObservable()
        self.users = _users.asObservable()
        self.isFetchingUsers = _isFetchingUsers.asObservable()

        let query = _feachUsersWithQuery
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .share()

        let endCousor = _pageInfo
            .map { $0?.endCursor }
            .share()

        let initialLoad = query
            .filter { !$0.isEmpty }
            .withLatestFrom(endCousor) { ($0, $1) }

        let loadMore = _fetchUsers
            .withLatestFrom(Observable.combineLatest(query, endCousor)) { $1 }
            .filter { !$0.isEmpty && $1 != nil }

        query
            .subscribe(onNext: { [_users] _ in
                _pageInfo.accept(nil)
                _users.accept([])
                _totalCount.accept(0)
            })
            .disposed(by: disposeBag)

        let requestWillStart = Observable.merge(initialLoad, loadMore)
            .map { SearchUserRequest(query: $0, after: $1) }
            .distinctUntilChanged { $0.query == $1.query && $0.after == $1.after }
            .share()

        let response = requestWillStart
            .do(onNext: { [_isFetchingUsers] _ in
                _isFetchingUsers.accept(true)
            })
            .flatMapLatest { request -> Observable<Event<Response<User>>> in
                ApiSession.shared.rx.send(request)
                    .materialize()
            }
            .do(onNext: { [_isFetchingUsers] _ in
                _isFetchingUsers.accept(false)
            })
            .share()

        response
            .flatMap { response -> Observable<Response<User>> in
                response.element.map(Observable.just) ?? .empty()
            }
            .subscribe(onNext: { [_users] response in
                _pageInfo.accept(response.pageInfo)
                _users.accept(_users.value + response.nodes)
                _totalCount.accept(response.totalCount)
            })
            .disposed(by: disposeBag)

        self.errorMessage = response
            .flatMap { response -> Observable<ErrorMessage> in
                guard case .emptyToken? = (response.error as? ApiSession.Error) else {
                    return .empty()
                }
                let title = "Access Token Error"
                let message = "\"Github Personal Access Token\" is Required.\n Please set it in ApiSession.extension.swift!"
                return .just(ErrorMessage(title: title, message: message))
            }
            .share()
    }

    func fetchUsers(withQuery query: String) {
        _feachUsersWithQuery.accept(query)
    }

    func fetchUsers() {
        _fetchUsers.accept(())
    }
}
