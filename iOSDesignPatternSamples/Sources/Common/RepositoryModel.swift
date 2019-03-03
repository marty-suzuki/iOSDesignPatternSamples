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

    let repositories: Observable<[Repository]>
    let isFetchingRepositories: Observable<Bool>
    let totalCount: Observable<Int>

    var repositoriesValue: [Repository] {
        return _repositories.value
    }

    var isFetchingRepositoriesValue: Bool {
        return _isFetchingRepositories.value
    }

    private let _repositories = BehaviorRelay<[Repository]>(value: [])
    private let _isFetchingRepositories = BehaviorRelay<Bool>(value: false)
    private let disposeBag = DisposeBag()

    private let _fetchRepositories = PublishRelay<Void>()

    init(user: User) {

        let _pageInfo = BehaviorRelay<PageInfo?>(value: nil)
        let _totalCount = BehaviorRelay<Int>(value: 0)

        self.totalCount = _totalCount.asObservable()
        self.repositories = _repositories.asObservable()
        self.isFetchingRepositories = _isFetchingRepositories.asObservable()

        let requestTrigger = _pageInfo.map { (user, $0?.endCursor) }
            .share(replay: 1, scope: .whileConnected)

        let initialLoadRequest = _fetchRepositories
            .withLatestFrom(requestTrigger)
            .filter { $1 == nil }

        let loadMoreRequest = _fetchRepositories
            .withLatestFrom(requestTrigger)
            .filter { $1 != nil }

        let willStartRequest = Observable.merge(initialLoadRequest, loadMoreRequest)
            .map { UserNodeRequest(id: $0.id, after: $1) }
            .distinctUntilChanged { $0.id == $1.id && $0.after == $1.after }
            .share()

        willStartRequest
            .do(onNext: { [_isFetchingRepositories] _ in
                _isFetchingRepositories.accept(true)
            })
            .flatMap {
                ApiSession.shared.rx.send($0)
                    .catchError { _ in .empty() }
            }
            .do(onNext: { [_isFetchingRepositories] _ in
                _isFetchingRepositories.accept(false)
            })
            .subscribe(onNext: { [_repositories] response in
                _pageInfo.accept(response.pageInfo)
                _repositories.accept(_repositories.value + response.nodes)
                _totalCount.accept(response.totalCount)
            })
            .disposed(by: disposeBag)
    }

    func fetchRepositories() {
        _fetchRepositories.accept(())
    }
}
