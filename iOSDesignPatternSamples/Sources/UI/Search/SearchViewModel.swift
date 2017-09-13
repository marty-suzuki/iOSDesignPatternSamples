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
    
    var usersValue: [User] { return _users.value }
    var isFetchingUsersValue: Bool { return _isFetchingUsers.value }
    
    private let _keyboardWillShow = PublishSubject<UIKeyboardInfo>()
    private let _keyboardWillHide = PublishSubject<UIKeyboardInfo>()
    private let _countString = PublishSubject<String>()
    private let _reloadData = PublishSubject<Void>()
    private let _users = Variable<[User]>([])
    private let _isFetchingUsers = Variable<Bool>(false)
    private let pageInfo = Variable<PageInfo?>(nil)
    private let totalCount = Variable<Int>(0)
    private let disposeBag = DisposeBag()
    
    private var pool = NoticeObserverPool()

    init(viewWillAppear: Observable<Void>,
         viewWillDisappear: Observable<Void>,
         viewDidAppear: Observable<Void>,
         searchText: ControlProperty<String>,
         isReachedBottom: Observable<Bool>,
         selectedIndexPath: Observable<IndexPath>,
         headerFooterView: Observable<UIView>) {
        self.keyboardWillShow = _keyboardWillShow
        self.keyboardWillHide = _keyboardWillHide
        self.countString = _countString
        self.reloadData = _reloadData
        self.accessTokenAlert = viewDidAppear
            .flatMap { _ -> Observable<(String, String)> in
                let token = ApiSession.shared.token ?? ""
                guard token.isEmpty || token == "Your Github Personal Access Token" else {
                    return .empty()
                }
                let title = "Access Token Error"
                let message = "\"Github Personal Access Token\" is Required.\n Please set it to ApiSession.shared.token in AppDelegate."
                return .just((title, message))
            }
        self.updateLoadingView = Observable.combineLatest(headerFooterView,
                                                          _isFetchingUsers.asObservable())
        self.selectedUser = selectedIndexPath
            .withLatestFrom(_users.asObservable()) { $1[$0.row] }

        Observable.zip(totalCount.asObservable(), _users.asObservable())
            { "\($1.count) / \($0)" }
            .bind(to: _countString)
            .disposed(by: disposeBag)
        Observable.merge(_users.asObservable().map { _ in },
                         totalCount.asObservable().map { _ in },
                         _isFetchingUsers.asObservable().map { _ in })
            .bind(to: _reloadData)
            .disposed(by: disposeBag)

        // keyboard notification
        viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let me = self else { return }
                UIKeyboardWillShow.observe { [weak self] in
                    self?._keyboardWillShow.onNext($0)
                }.addObserverTo(me.pool)
                UIKeyboardWillHide.observe { [weak self] in
                    self?._keyboardWillHide.onNext($0)
                }.addObserverTo(me.pool)
            })
            .disposed(by: disposeBag)
        viewWillDisappear
            .subscribe(onNext: { [weak self] in
                self?.pool = NoticeObserverPool()
            })
            .disposed(by: disposeBag)

        // fetch users
        let nonEmptyQuery = searchText
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .do(onNext: { [weak self] _ in
                self?._users.value.removeAll()
                self?.pageInfo.value = nil
                self?.totalCount.value = 0
            })
            .filter { !$0.isEmpty }
            .share(replay: 1, scope: .whileConnected)
        let endCousor = pageInfo.asObservable()
            .map { $0?.endCursor }
        let initialLoad = nonEmptyQuery.withLatestFrom(endCousor) { ($0, $1) }
        let loadMore = isReachedBottom
            .filter { $0 }
            .withLatestFrom(Observable.combineLatest(nonEmptyQuery, endCousor)) { $1 }
            .filter { $1 != nil }
        Observable.merge(initialLoad, loadMore)
            .map { SearchUserRequest(query: $0, after: $1) }
            .distinctUntilChanged { $0.query == $1.query && $0.after == $1.after }
            .do(onNext: { [weak self] _ in
                self?._isFetchingUsers.value = true
            })
            .flatMapLatest { ApiSession.shared.rx.send($0) }
            .subscribe(onNext: { [weak self] (response: Response<User>) in
                self?.pageInfo.value = response.pageInfo
                self?._users.value.append(contentsOf: response.nodes)
                self?.totalCount.value = response.totalCount
                self?._isFetchingUsers.value = false
            })
            .disposed(by: disposeBag)
    }
}
