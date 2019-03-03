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
        return model.usersValue
    }

    var isFetchingUsers: Bool {
        return model.isFetchingUsersValue
    }

    private let model: SearchModel
    private let disposeBag = DisposeBag()

    init(favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>) {

        self.model = SearchModel()

        let viewDidAppear = PublishRelay<Void>()
        let viewDidDisappear = PublishRelay<Void>()
        let searchText = PublishRelay<String?>()
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

        do {
            let selectedUser = selectedIndexPath
                .withLatestFrom(model.users) { $1[$0.row] }

            let updateLoadingView = Observable.combineLatest(headerFooterView, model.isFetchingUsers)

            let countString = Observable.combineLatest(model.totalCount, model.users)
                .map { "\($1.count) / \($0)" }
                .share(replay: 1, scope: .whileConnected)

            let reloadData = Observable.merge(model.users.map { _ in },
                                              model.totalCount.map { _ in },
                                              model.isFetchingUsers.map { _ in })

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

            self.output = Output(accessTokenAlert: model.errorMessage,
                                 updateLoadingView: updateLoadingView,
                                 selectedUser: selectedUser,
                                 keyboardWillShow: keyboardWillShow,
                                 keyboardWillHide: keyboardWillHide,
                                 countString: countString,
                                 reloadData: reloadData,
                                 favorites: favoritesOutput)
        }

        searchText
            .map { $0 ?? "" }
            .subscribe(onNext: { [model] in
                model.fetchUsers(withQuery: $0)
            })
            .disposed(by: disposeBag)

        isReachedBottom
            .distinctUntilChanged()
            .filter { $0 }
            .subscribe(onNext: { [model] _ in
                model.fetchUsers()
            })
            .disposed(by: disposeBag)
    }
}

extension SearchViewModel {
    struct Input {
        let viewDidAppear: AnyObserver<Void>
        let viewDidDisappear: AnyObserver<Void>
        let searchText: AnyObserver<String?>
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
