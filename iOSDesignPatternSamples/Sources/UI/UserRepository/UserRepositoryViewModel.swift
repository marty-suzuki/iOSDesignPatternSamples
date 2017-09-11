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
    private let disposeBag = DisposeBag()

    var repositoriesValue: [Repository] { return _reposiroties.value }
    private let _reposiroties = Variable<[Repository]>([])
    var isFetchingRepositoriesValue: Bool { return _isFetchingRepositories.value }
    private let _isFetchingRepositories = Variable<Bool>(false)

    let title: Observable<String>

    let showRepository: Observable<Repository>
    private let _showRepository = PublishSubject<Repository>()
    let updateLoadingView: Observable<(UIView, Bool)>
    private let _updateLoadingView = PublishSubject<(UIView, Bool)>()
    let countString: Observable<String>
    private let _countString = PublishSubject<String>()
    let reloadData: Observable<Void>
    private let _reloadData = PublishSubject<Void>()

    private let pageInfo = Variable<PageInfo?>(nil)
    private let totalCount = Variable<Int>(0)

    init(user: User,
         fetchRepositories: Observable<Void>,
         selectedIndexPath: Observable<IndexPath>,
         isReachedBottom: Observable<Bool>,
         headerFooterView: Observable<UIView>) {
        self.showRepository = _showRepository
        self.updateLoadingView = _updateLoadingView
        self.countString = _countString
        self.reloadData = _reloadData

        self.title = Observable.of("\(user.login)'s Repositories")

        Observable.combineLatest(totalCount.asObservable(), _reposiroties.asObservable())
            { "\($1.count) / \($0)" }
            .bind(to: _countString)
            .disposed(by: disposeBag)

        Observable.combineLatest(headerFooterView, _isFetchingRepositories.asObservable())
            .bind(to: _updateLoadingView)
            .disposed(by: disposeBag)

        Observable.merge(_reposiroties.asObservable().map { _ in },
                         totalCount.asObservable().map { _ in },
                         _isFetchingRepositories.asObservable().map { _ in })
            .bind(to: _reloadData)
            .disposed(by: disposeBag)

        selectedIndexPath
            .withLatestFrom(_reposiroties.asDriver()) { $1[$0.row] }
            .bind(to: _showRepository)
            .disposed(by: disposeBag)

        // fetch repositories
        let endCousor = pageInfo.asObservable()
            .flatMap { pageInfo -> Observable<String?> in
                if let pageInfo = pageInfo, !pageInfo.hasNextPage || pageInfo.endCursor == nil {
                    return .empty()
                }
                return .just(pageInfo?.endCursor)
            }
        let searchInfo = Observable.combineLatest(Observable<User>.just(user), endCousor)
            .share(replay: 1, scope: .whileConnected)
        let loadMoreSearchInfo = isReachedBottom
            .filter { $0 }
            .withLatestFrom(searchInfo)
        let fetchSearchInfo = fetchRepositories
            .withLatestFrom(searchInfo)
        Observable.merge(searchInfo, loadMoreSearchInfo, fetchSearchInfo)
            .do(onNext: { [weak self] _ in
                self?._isFetchingRepositories.value = true
            })
            .flatMap { (user, endCursor) -> Observable<Response<Repository>> in
                let request = UserNodeRequest(id: user.id, after: endCursor)
                return ApiSession.shared.rx.send(request)
            }
            .subscribe(onNext: { [weak self] response in
                self?.pageInfo.value = response.pageInfo
                self?._reposiroties.value.append(contentsOf: response.nodes)
                self?.totalCount.value = response.totalCount
                self?._isFetchingRepositories.value = false
            })
            .disposed(by: disposeBag)
    }
}
