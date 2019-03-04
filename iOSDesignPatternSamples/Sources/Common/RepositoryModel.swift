//
//  RepositoryModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2019/03/01.
//  Copyright © 2019 marty-suzuki. All rights reserved.
//

import GithubKit
import RxCocoa
import RxSwift

final class RepositoryModel {

    let response: Observable<Response<Repository>>
    let isFetchingRepositories: Observable<Bool>

    private let _fetchRepositories = PublishRelay<(String, String?)>()

    init() {
        let _isFetchingRepositories = PublishRelay<Bool>()
        self.isFetchingRepositories = _isFetchingRepositories.asObservable()

        self.response = _fetchRepositories
            .do(onNext: { _ in
                _isFetchingRepositories.accept(true)
            })
            .flatMap { id, after -> Observable<Response<Repository>> in
                let request = UserNodeRequest(id: id, after: after)
                return ApiSession.shared.rx.send(request)
                    .catchError { _ in .empty() }
            }
            .do(onNext: { _ in
                _isFetchingRepositories.accept(false)
            })
            .share()
    }

    func fetchRepositories(withUserID id: String, after: String?) {
        _fetchRepositories.accept((id, after))
    }
}
