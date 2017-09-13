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
    var repositoriesValue: [Repository] { return _reposiroties.value }
    var isFetchingRepositoriesValue: Bool { return _isFetchingRepositories.value }
    
    let title: Observable<String>
    let updateLoadingView: Observable<(UIView, Bool)>
    let showRepository: Observable<Repository>
    let countString: Observable<String>
    let reloadData: Observable<Void>
    
    private let _countString = PublishSubject<String>()
    private let _reloadData = PublishSubject<Void>()
    private let _reposiroties = Variable<[Repository]>([])
    private let _isFetchingRepositories = Variable<Bool>(false)
    private let pageInfo = Variable<PageInfo?>(nil)
    private let totalCount = Variable<Int>(0)
    private let disposeBag = DisposeBag()

    init(user: User,
         fetchRepositories: Observable<Void>,
         selectedIndexPath: Observable<IndexPath>,
         isReachedBottom: Observable<Bool>,
         headerFooterView: Observable<UIView>) {
        self.countString = _countString
        self.reloadData = _reloadData
        self.title = Observable.of("\(user.login)'s Repositories")
        self.updateLoadingView = Observable.combineLatest(headerFooterView,
                                                          _isFetchingRepositories.asObservable())
        self.showRepository = selectedIndexPath
            .withLatestFrom(_reposiroties.asDriver()) { $1[$0.row] }

        Observable.combineLatest(totalCount.asObservable(), _reposiroties.asObservable())
            { "\($1.count) / \($0)" }
            .bind(to: _countString)
            .disposed(by: disposeBag)
        Observable.merge(_reposiroties.asObservable().map { _ in },
                         totalCount.asObservable().map { _ in },
                         _isFetchingRepositories.asObservable().map { _ in })
            .bind(to: _reloadData)
            .disposed(by: disposeBag)

        // fetch repositories
        let endCousor = pageInfo.asObservable()
            .map { $0?.endCursor }
        let params = Observable.combineLatest(Observable<User>.just(user), endCousor)
            .share(replay: 1, scope: .whileConnected)
        let initialLoadRequest = fetchRepositories
            .withLatestFrom(params)
        let loadMoreRequest = isReachedBottom
            .filter { $0 }
            .withLatestFrom(params)
            .filter { $1 != nil }
        Observable.merge(initialLoadRequest, loadMoreRequest)
            .map { UserNodeRequest(id: $0.id, after: $1) }
            .distinctUntilChanged { $0.id == $1.id && $0.after == $1.after }
            .do(onNext: { [weak self] _ in
                self?._isFetchingRepositories.value = true
            })
            .flatMap { ApiSession.shared.rx.send($0) }
            .subscribe(onNext: { [weak self] (response: Response<Repository>) in
                self?.pageInfo.value = response.pageInfo
                self?._reposiroties.value.append(contentsOf: response.nodes)
                self?.totalCount.value = response.totalCount
                self?._isFetchingRepositories.value = false
            })
            .disposed(by: disposeBag)
    }
}
