//
//  UserRepositoryViewModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit
import RxSwift
import RxCocoa

final class UserRepositoryViewModel {
    let title: String

    var repositories: [Repository] {
        return _repositories.value
    }

    var isFetchingRepositories: Bool {
        return _isFetchingRepositories.value
    }

    let output: Output
    let input: Input

    fileprivate let _repositories = BehaviorRelay<[Repository]>(value: [])
    fileprivate let _isFetchingRepositories = BehaviorRelay<Bool>(value: false)
    private let pageInfo = BehaviorRelay<PageInfo?>(value: nil)
    private let totalCount = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()

    init(user: User,
         favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>) {
        self.title = "\(user.login)'s Repositories"

        let _fetchRepositories = PublishRelay<Void>()
        let _selectedIndexPath = PublishRelay<IndexPath>()
        let _isReachedBottom = PublishRelay<Bool>()
        let _headerFooterView = PublishRelay<UIView>()

        self.input = Input(fetchRepositories: _fetchRepositories.asObserver(),
                           selectedIndexPath: _selectedIndexPath.asObserver(),
                           isReachedBottom: _isReachedBottom.asObserver(),
                           headerFooterView: _headerFooterView.asObserver(),
                           favorites: favoritesInput)

        do {
            let updateLoadingView = Observable.combineLatest(_headerFooterView,
                                                             _isFetchingRepositories.asObservable())

            let showRepository = _selectedIndexPath
                .withLatestFrom(_repositories.asObservable()) { $1[$0.row] }

            let countString = Observable.combineLatest(totalCount.asObservable(),
                                                       _repositories.asObservable())
                .map { "\($1.count) / \($0)" }
                .share(replay: 1, scope: .whileConnected)

            let reloadData = Observable.merge(_repositories.asObservable().map { _ in },
                                              totalCount.asObservable().map { _ in },
                                              _isFetchingRepositories.asObservable().map { _ in })

            self.output = Output(updateLoadingView: updateLoadingView,
                                 showRepository: showRepository,
                                 countString: countString,
                                 reloadData: reloadData,
                                 favorites: favoritesOutput)
        }

        // fetch repositories
        let _requestTrigger = PublishRelay<(User, String?)>()

        let initialLoadRequest = _fetchRepositories
            .withLatestFrom(_requestTrigger)

        let loadMoreRequest = _isReachedBottom
            .distinctUntilChanged()
            .filter { $0 }
            .withLatestFrom(_requestTrigger)
            .filter { $1 != nil }

        let willStartRequest = Observable.merge(initialLoadRequest, loadMoreRequest)
            .map { UserNodeRequest(id: $0.id, after: $1) }
            .distinctUntilChanged { $0.id == $1.id && $0.after == $1.after }
            .share()

        willStartRequest
            .map { _ in true }
            .bind(to: _isFetchingRepositories)
            .disposed(by: disposeBag)

        willStartRequest
            .flatMap { ApiSession.shared.rx.send($0) }
            .subscribe(onNext: { [weak self] (response: Response<Repository>) in
                guard let me = self else { return }
                me.pageInfo.accept(response.pageInfo)
                me._repositories.accept(me._repositories.value + response.nodes)
                me.totalCount.accept(response.totalCount)
                me._isFetchingRepositories.accept(false)
            })
            .disposed(by: disposeBag)

        Observable.combineLatest(Observable<User>.just(user),
                                 pageInfo.asObservable().map { $0?.endCursor })
            .bind(to: _requestTrigger)
            .disposed(by: disposeBag)
    }
}

extension UserRepositoryViewModel {
    struct Output {
        let updateLoadingView: Observable<(UIView, Bool)>
        let showRepository: Observable<Repository>
        let countString: Observable<String>
        let reloadData: Observable<Void>
        let favorites: Observable<[Repository]>
    }

    struct Input {
        let fetchRepositories: AnyObserver<Void>
        let selectedIndexPath: AnyObserver<IndexPath>
        let isReachedBottom: AnyObserver<Bool>
        let headerFooterView: AnyObserver<UIView>
        let favorites: AnyObserver<[Repository]>
    }
}
