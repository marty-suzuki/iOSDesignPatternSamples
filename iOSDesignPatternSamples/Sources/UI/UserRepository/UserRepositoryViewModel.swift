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

    let updateLoadingView: Observable<(UIView, Bool)>
    let showRepository: Observable<Repository>
    let countString: Observable<String>
    let reloadData: Observable<Void>
    
    fileprivate let _repositories = BehaviorRelay<[Repository]>(value: [])
    fileprivate let _isFetchingRepositories = BehaviorRelay<Bool>(value: false)
    private let pageInfo = BehaviorRelay<PageInfo?>(value: nil)
    private let totalCount = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()

    init(user: User,
         fetchRepositories: Observable<Void>,
         selectedIndexPath: Observable<IndexPath>,
         isReachedBottom: Observable<Bool>,
         headerFooterView: Observable<UIView>) {

        self.title = "\(user.login)'s Repositories"

        let _countString = PublishSubject<String>()
        let _reloadData = PublishSubject<Void>()

        self.countString = _countString
        self.reloadData = _reloadData
        self.updateLoadingView = Observable.combineLatest(headerFooterView,
                                                          _isFetchingRepositories.asObservable())
        self.showRepository = selectedIndexPath
            .withLatestFrom(_repositories.asObservable()) { $1[$0.row] }

        Observable.combineLatest(totalCount.asObservable(),
                                 _repositories.asObservable())
            .map { "\($1.count) / \($0)" }
            .bind(to: _countString)
            .disposed(by: disposeBag)

        Observable.merge(_repositories.asObservable().map { _ in },
                         totalCount.asObservable().map { _ in },
                         _isFetchingRepositories.asObservable().map { _ in })
            .bind(to: _reloadData)
            .disposed(by: disposeBag)

        // fetch repositories
        let _requestTrigger = PublishSubject<(User, String?)>()

        let initialLoadRequest = fetchRepositories
            .withLatestFrom(_requestTrigger)

        let loadMoreRequest = isReachedBottom
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

extension UserRepositoryViewModel: ValueCompatible {}

extension Value where Base == UserRepositoryViewModel {
    var repositories: [Repository] {
        return base._repositories.value
    }

    var isFetchingRepositories: Bool {
        return base._isFetchingRepositories.value
    }
}
