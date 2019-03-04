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
    let response: Observable<Response<User>>
    let isFetchingUsers: Observable<Bool>

    private let _fetchUser = PublishRelay<(String, String?)>()

    init() {
        let _isFetchingUsers = PublishRelay<Bool>()
        self.isFetchingUsers = _isFetchingUsers.asObservable()

        let response = _fetchUser
            .do(onNext: { _ in
                _isFetchingUsers.accept(true)
            })
            .flatMap { query, after -> Observable<Event<Response<User>>> in
                let request = SearchUserRequest(query: query, after: after)
                return ApiSession.shared.rx.send(request)
                    .materialize()
            }
            .do(onNext: { _ in
                _isFetchingUsers.accept(false)
            })
            .share()

        self.response = response
            .flatMap { $0.element.map(Observable.just) ?? .empty() }
            .share()

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

    func fetchUsers(withQuery query: String, after: String?) {
        _fetchUser.accept((query, after))
    }
}
