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
    private let disposeBag = DisposeBag()
    private var pool = NoticeObserverPool()

    let accessTokenAlert: Observable<(String, String)>
    let keyboardWillShow: Observable<UIKeyboardInfo>
    private let _keyboardWillShow = PublishSubject<UIKeyboardInfo>()
    let keyboardWillHide: Observable<UIKeyboardInfo>
    private let _keyboardWillHide = PublishSubject<UIKeyboardInfo>()
    let countString: Observable<String>
    private let _countString = PublishSubject<String>()
    let reloadData: Observable<Void>
    private let _reloadData = PublishSubject<Void>()
    let updateLoadingView: Observable<(UIView, Bool)>
    private let _updateLoadingView = PublishSubject<(UIView, Bool)>()
    let selectedUser: Observable<User>
    private let _selectedUser = PublishSubject<User>()

    var usersValue: [User] { return _users.value }
    private let _users = Variable<[User]>([])
    var isFetchingUsersValue: Bool { return _isFetchingUsers.value }
    private let _isFetchingUsers = Variable<Bool>(false)

    private let pageInfo = Variable<PageInfo?>(nil)
    private let totalCount = Variable<Int>(0)

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
        self.updateLoadingView = _updateLoadingView
        self.selectedUser = _selectedUser
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

        Observable.combineLatest(totalCount.asObservable(), _users.asObservable())
            { "\($1.count) / \($0)" }
            .bind(to: _countString)
            .disposed(by: disposeBag)

        Observable.combineLatest(headerFooterView, _isFetchingUsers.asObservable())
            .bind(to: _updateLoadingView)
            .disposed(by: disposeBag)

        Observable.merge(_users.asObservable().map { _ in },
                         totalCount.asObservable().map { _ in },
                         _isFetchingUsers.asObservable().map { _ in })
            .bind(to: _reloadData)
            .disposed(by: disposeBag)

        selectedIndexPath
            .withLatestFrom(_users.asObservable()) { $1[$0.row] }
            .bind(to: _selectedUser)
            .disposed(by: disposeBag)

        // keyboard notification
        viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let me = self else { return }
                UIKeyboardWillShow.observe { [weak self] in
                    self?._keyboardWillShow.onNext($0)
                }
                .addObserverTo(me.pool)

                UIKeyboardWillHide.observe { [weak self] in
                    self?._keyboardWillHide.onNext($0)
                }
                .addObserverTo(me.pool)
            })
            .disposed(by: disposeBag)

        viewWillDisappear
            .subscribe(onNext: { [weak self] in
                self?.pool = NoticeObserverPool()
            })
            .disposed(by: disposeBag)

        // fetch users
        let nonEmptyQuery = searchText.filter { !$0.isEmpty }
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .do(onNext: { [weak self] _ in
                self?._users.value.removeAll()
                self?.pageInfo.value = nil
                self?.totalCount.value = 0
            })
        let endCousor = pageInfo.asObservable()
            .flatMap { pageInfo -> Observable<String?> in
                if let pageInfo = pageInfo, !pageInfo.hasNextPage || pageInfo.endCursor == nil {
                    return .empty()
                }
                return .just(pageInfo?.endCursor)
            }
        let searchInfo = nonEmptyQuery.withLatestFrom(endCousor) { ($0, $1) }
        let loadModeSearchInfo = isReachedBottom
            .filter { $0 }
            .withLatestFrom(searchInfo)
        Observable.merge(searchInfo, loadModeSearchInfo)
            .distinctUntilChanged { $0.0 == $1.0 && $0.1 == $1.1 }
            .do(onNext: { [weak self] _ in
                self?._isFetchingUsers.value = true
            })
            .flatMapLatest { (query, endCursor) -> Observable<Response<User>> in
                let request = SearchUserRequest(query: query, after: endCursor)
                return ApiSession.shared.rx.send(request)
            }
            .subscribe(onNext: { [weak self] response in
                self?.pageInfo.value = response.pageInfo
                self?._users.value.append(contentsOf: response.nodes)
                self?.totalCount.value = response.totalCount
                self?._isFetchingUsers.value = false
            })
            .disposed(by: disposeBag)
    }
}
