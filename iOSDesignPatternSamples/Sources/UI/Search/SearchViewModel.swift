//
//  SearchViewModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import Foundation
import GithubKit
import UIKit

final class SearchViewModel {
    let output: Output
    let input: Input

    var users: [User] {
        model.users
    }

    var isFetchingUsers: Bool {
        model.isFetchingUsers
    }

    private let model: SearchModel
    private var cancellables = Set<AnyCancellable>()

    init(favoritesOutput: AnyPublisher<[Repository], Never>,
         favoritesInput: @escaping ([Repository]) -> Void) {
        let model = SearchModel()
        self.model = model

        let viewDidAppear = PassthroughSubject<Void, Never>()
        let viewDidDisappear = PassthroughSubject<Void, Never>()
        let searchText = PassthroughSubject<String?, Never>()
        let isReachedBottom = PassthroughSubject<Bool, Never>()
        let selectedIndexPath = PassthroughSubject<IndexPath, Never>()
        let headerFooterView = PassthroughSubject<UIView, Never>()

        self.input = Input(viewDidAppear: viewDidAppear.send,
                           viewDidDisappear: viewDidDisappear.send,
                           searchText: searchText.send,
                           isReachedBottom: isReachedBottom.send,
                           selectedIndexPath: selectedIndexPath.send,
                           headerFooterView: headerFooterView.send,
                           favorites: favoritesInput)

        do {
            let selectedUser = selectedIndexPath
                .map { model.users[$0.row] }
                .eraseToAnyPublisher()

            let updateLoadingView = headerFooterView
                .combineLatest(model.isFetchingUsersPublisher)
                .eraseToAnyPublisher()

            let countString = model.totalCountPublisher
                .combineLatest(model.usersPublisher)
                .map { "\($1.count) / \($0)" }
                .eraseToAnyPublisher()

            let reloadData = model.usersPublisher.map { _ in }
                .merge(
                    with:
                        model.totalCountPublisher.map { _ in },
                        model.isFetchingUsersPublisher.map { _ in }
                )
                .eraseToAnyPublisher()

            // keyboard notification
            let isViewAppearing = viewDidAppear.map { true }
                .merge(with: viewDidDisappear.map { false })
                .eraseToAnyPublisher()

            let makeKeyboardObservable: (Notification.Name, Bool) -> AnyPublisher<UIKeyboardInfo, Never> = { name, isViewAppearing in
                guard isViewAppearing else {
                    return Empty().eraseToAnyPublisher()
                }
                return NotificationCenter.default.publisher(for: name)
                    .flatMap { notification -> AnyPublisher<UIKeyboardInfo, Never> in
                        guard let info = UIKeyboardInfo(notification: notification) else {
                            return Empty().eraseToAnyPublisher()
                        }
                        return Just(info).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }

            let keyboardWillShow = isViewAppearing
                .map { makeKeyboardObservable(UIResponder.keyboardWillShowNotification, $0) }
                .switchToLatest()
                .eraseToAnyPublisher()

            let keyboardWillHide = isViewAppearing
                .map { makeKeyboardObservable(UIResponder.keyboardWillHideNotification, $0) }
                .switchToLatest()
                .eraseToAnyPublisher()

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
            .sink {
                model.fetchUsers(withQuery: $0)
            }
            .store(in: &cancellables)

        isReachedBottom
            .removeDuplicates()
            .filter { $0 }
            .sink { _ in
                model.fetchUsers()
            }
            .store(in: &cancellables)
    }
}

extension SearchViewModel {
    struct Input {
        let viewDidAppear: () -> Void
        let viewDidDisappear: () -> Void
        let searchText: (String?) -> Void
        let isReachedBottom: (Bool) -> Void
        let selectedIndexPath: (IndexPath) -> Void
        let headerFooterView: (UIView) -> Void
        let favorites: ([Repository]) -> Void
    }

    struct Output {
        let accessTokenAlert: AnyPublisher<ErrorMessage, Never>
        let updateLoadingView: AnyPublisher<(UIView, Bool), Never>
        let selectedUser: AnyPublisher<User, Never>
        let keyboardWillShow: AnyPublisher<UIKeyboardInfo, Never>
        let keyboardWillHide: AnyPublisher<UIKeyboardInfo, Never>
        let countString: AnyPublisher<String, Never>
        let reloadData: AnyPublisher<Void, Never>
        let favorites: AnyPublisher<[Repository], Never>
    }
}
