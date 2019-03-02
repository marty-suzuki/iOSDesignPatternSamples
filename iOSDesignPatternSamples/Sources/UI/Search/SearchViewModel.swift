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
    let output: Output
    let input: Input

    var users: [User] {
        return _users.value
    }

    var isFetchingUsers: Bool {
        return _isFetchingUsers.value
    }

    fileprivate let _users = BehaviorRelay<[User]>(value: [])
    fileprivate let _isFetchingUsers = BehaviorRelay<Bool>(value: false)
    private let pageInfo = BehaviorRelay<PageInfo?>(value: nil)
    private let totalCount = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()

    init(favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>) {

        let viewDidAppear = PublishRelay<Void>()
        let viewDidDisappear = PublishRelay<Void>()
        let searchText = PublishRelay<String>()
        let isReachedBottom = PublishRelay<Bool>()
        let selectedIndexPath = PublishRelay<IndexPath>()
        let headerFooterView = PublishRelay<UIView>()

        self.input = Input(viewDidAppear: viewDidAppear.asObserver(),
                           viewDidDisappear: viewDidDisappear.asObserver(),
                           searchText: searchText.asObserver(),
                           isReachedBottom: isReachedBottom.asObserver(),
                           selectedIndexPath: selectedIndexPath.asObserver(),
                           headerFooterView: headerFooterView.asObserver(),
                           favorites: favoritesInput)

        let _accessTokenAlert = PublishRelay<ErrorMessage>()

        do {
            let selectedUser = selectedIndexPath
                .withLatestFrom(_users.asObservable()) { $1[$0.row] }

            let updateLoadingView = Observable.combineLatest(headerFooterView,
                                                             _isFetchingUsers.asObservable())

            let countString = Observable.zip(totalCount.asObservable(),
                                             _users.asObservable())
                .map { "\($1.count) / \($0)" }
                .share(replay: 1, scope: .whileConnected)

            let reloadData = Observable.merge(_users.asObservable().map { _ in },
                                              totalCount.asObservable().map { _ in },
                                              _isFetchingUsers.asObservable().map { _ in })

            // keyboard notification
            let isViewAppearing = Observable.merge(viewDidAppear.map { true },
                                                   viewDidDisappear.map { false })

            let makeKeyboardObservable: (Notice.Name<UIKeyboardInfo>, Bool) -> Observable<UIKeyboardInfo> = { name, isViewAppearing in
                guard isViewAppearing else {
                    return .empty()
                }
                return Observable.create { observer in
                    let observation = NotificationCenter.default.nok.observe(name: name) {
                        observer.onNext($0)
                    }
                    return Disposables.create {
                        observation.invalidate()
                    }
                }
            }

            let keyboardWillShow = isViewAppearing
                .flatMapLatest { makeKeyboardObservable(.keyboardWillShow, $0) }

            let keyboardWillHide = isViewAppearing
                .flatMapLatest { makeKeyboardObservable(.keyboardWillHide, $0) }

            self.output = Output(accessTokenAlert: _accessTokenAlert.asObservable(),
                                 updateLoadingView: updateLoadingView,
                                 selectedUser: selectedUser,
                                 keyboardWillShow: keyboardWillShow,
                                 keyboardWillHide: keyboardWillHide,
                                 countString: countString,
                                 reloadData: reloadData,
                                 favorites: favoritesOutput)
        }

        // fetch users
        let _searchTrigger = PublishRelay<String>()

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
            .flatMap { response -> Observable<ErrorMessage> in
                guard case .emptyToken? = (response.1 as? ApiSession.Error) else { return .empty() }
                let title = "Access Token Error"
                let message = "\"Github Personal Access Token\" is Required.\n Please set it in ApiSession.extension.swift!"
                return .just(ErrorMessage(title: title, message: message))
            }
            .bind(to: _accessTokenAlert)
            .disposed(by: disposeBag)

        searchText
            .bind(to: _searchTrigger)
            .disposed(by: disposeBag)
    }
}

extension SearchViewModel {
    struct Input {
        let viewDidAppear: AnyObserver<Void>
        let viewDidDisappear: AnyObserver<Void>
        let searchText: AnyObserver<String>
        let isReachedBottom: AnyObserver<Bool>
        let selectedIndexPath: AnyObserver<IndexPath>
        let headerFooterView: AnyObserver<UIView>
        let favorites: AnyObserver<[Repository]>
    }

    struct Output {
        let accessTokenAlert: Observable<ErrorMessage>
        let updateLoadingView: Observable<(UIView, Bool)>
        let selectedUser: Observable<User>
        let keyboardWillShow: Observable<UIKeyboardInfo>
        let keyboardWillHide: Observable<UIKeyboardInfo>
        let countString: Observable<String>
        let reloadData: Observable<Void>
        let favorites: Observable<[Repository]>
    }
}
