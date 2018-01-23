//
//  SearchViewModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit
import NoticeObserveKit
import RxSwift
import RxCocoa

final class SearchViewModel {
    let accessTokenAlert: Observable<(String, String)>
    let updateLoadingView: Observable<(UIView, Bool)>
    let selectedUser: Observable<User>
    let keyboardWillShow: Observable<UIKeyboardInfo>
    let keyboardWillHide: Observable<UIKeyboardInfo>
    let countString: Observable<String>
    let reloadData: Observable<Void>

    fileprivate let _users = BehaviorRelay<[User]>(value: [])
    fileprivate let _isFetchingUsers = BehaviorRelay<Bool>(value: false)
    private let pageInfo = BehaviorRelay<PageInfo?>(value: nil)
    private let totalCount = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()
    
    private var pool = NoticeObserverPool()

    init(viewDidAppear: Observable<Void>,
         viewDidDisappear: Observable<Void>,
         searchText: ControlProperty<String>,
         isReachedBottom: Observable<Bool>,
         selectedIndexPath: Observable<IndexPath>,
         headerFooterView: Observable<UIView>) {

        let _keyboardWillShow = PublishSubject<UIKeyboardInfo>()
        let _keyboardWillHide = PublishSubject<UIKeyboardInfo>()
        let _countString = PublishSubject<String>()
        let _reloadData = PublishSubject<Void>()
        let _accessTokenAlert = PublishSubject<(String, String)>()

        self.keyboardWillShow = _keyboardWillShow
        self.keyboardWillHide = _keyboardWillHide
        self.countString = _countString
        self.reloadData = _reloadData
        self.accessTokenAlert = _accessTokenAlert
        self.updateLoadingView = Observable.combineLatest(headerFooterView,
                                                          _isFetchingUsers.asObservable())
        self.selectedUser = selectedIndexPath
            .withLatestFrom(_users.asObservable()) { $1[$0.row] }

        Observable.zip(totalCount.asObservable(),
                       _users.asObservable())
            .map { "\($1.count) / \($0)" }
            .bind(to: _countString)
            .disposed(by: disposeBag)

        Observable.merge(_users.asObservable().map { _ in },
                         totalCount.asObservable().map { _ in },
                         _isFetchingUsers.asObservable().map { _ in })
            .bind(to: _reloadData)
            .disposed(by: disposeBag)

        // keyboard notification
        viewDidAppear
            .subscribe(onNext: { [weak self] in
                guard let me = self else { return }
                UIKeyboardWillShow.observe {
                    _keyboardWillShow.onNext($0)
                }
                .disposed(by: me.pool)

                UIKeyboardWillHide.observe {
                    _keyboardWillHide.onNext($0)
                }
                .disposed(by: me.pool)
            })
            .disposed(by: disposeBag)

        viewDidDisappear
            .subscribe(onNext: { [weak self] in
                self?.pool = NoticeObserverPool()
            })
            .disposed(by: disposeBag)

        // fetch users
        let _searchTrigger = PublishSubject<String>()

        let query = _searchTrigger
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .share()

        let endCousor = pageInfo.asObservable()
            .map { $0?.endCursor }
            .share()

        let initialLoad = query
            .filter { !$0.isEmpty }
            .withLatestFrom(endCousor) { ($0, $1) }

        let loadMore = isReachedBottom
            .distinctUntilChanged()
            .filter { $0 }
            .withLatestFrom(Observable.combineLatest(query, endCousor)) { $1 }
            .filter { !$0.isEmpty && $1 != nil }

        query
            .subscribe(onNext: { [weak self] _ in
                self?.pageInfo.accept(nil)
                self?._users.accept([])
                self?.totalCount.accept(0)
            })
            .disposed(by: disposeBag)

        let requestWillStart = Observable.merge(initialLoad, loadMore)
            .map { SearchUserRequest(query: $0, after: $1) }
            .distinctUntilChanged { $0.query == $1.query && $0.after == $1.after }
            .share()

        requestWillStart
            .map { _ in true }
            .bind(to: _isFetchingUsers)
            .disposed(by: disposeBag)

        let response = requestWillStart
            .flatMapLatest { request -> Observable<(Response<User>?, Error?)> in
                ApiSession.shared.rx.send(request)
                    .map { ($0, nil) }
                    .catchError { Observable.just((nil, $0)) }
            }
            .share()

        response
            .flatMap { response -> Observable<Response<User>> in
                response.0.map(Observable.just) ?? .empty()
            }
            .subscribe(onNext: { [weak self] (response: Response<User>) in
                guard let me = self else { return }
                me.pageInfo.accept(response.pageInfo)
                me._users.accept(me._users.value + response.nodes)
                me.totalCount.accept(response.totalCount)
                me._isFetchingUsers.accept(false)
            })
            .disposed(by: disposeBag)

        response
            .flatMap { response -> Observable<(String, String)> in
                guard case .emptyToken? = (response.1 as? ApiSession.Error) else { return .empty() }
                let title = "Access Token Error"
                let message = "\"Github Personal Access Token\" is Required.\n Please set it in ApiSession.extension.swift!"
                return .just((title, message))
            }
            .bind(to: _accessTokenAlert)
            .disposed(by: disposeBag)

        searchText
            .bind(to: _searchTrigger)
            .disposed(by: disposeBag)
    }
}

extension SearchViewModel: ValueCompatible {}

extension Value where Base == SearchViewModel {
    var users: [User] {
        return base._users.value
    }

    var isFetchingUsers: Bool {
        return base._isFetchingUsers.value
    }
}
