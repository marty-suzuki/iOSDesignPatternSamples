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

protocol SearchViewModelType: AnyObject {
    var input: SearchViewModel.Input { get }
    var output: SearchViewModel.Output { get }
}

final class SearchViewModel: SearchViewModelType{
    let output: Output
    let input: Input

    private var cancellables = Set<AnyCancellable>()

    init(
        searchModel: SearchModelType
    ) {
        let viewDidAppear = PassthroughSubject<Void, Never>()
        let viewDidDisappear = PassthroughSubject<Void, Never>()
        let searchText = PassthroughSubject<String?, Never>()
        let isReachedBottom = PassthroughSubject<Bool, Never>()
        let selectedIndexPath = PassthroughSubject<IndexPath, Never>()
        let headerFooterView = PassthroughSubject<UIView, Never>()

        self.input = Input(
            viewDidAppear: viewDidAppear.send,
            viewDidDisappear: viewDidDisappear.send,
            searchText: searchText.send,
            isReachedBottom: isReachedBottom.send,
            selectedIndexPath: selectedIndexPath.send,
            headerFooterView: headerFooterView.send
        )

        do {
            let selectedUser = selectedIndexPath
                .map { searchModel.users[$0.row] }
                .eraseToAnyPublisher()

            let updateLoadingView = headerFooterView
                .combineLatest(searchModel.isFetchingUsersPublisher)
                .eraseToAnyPublisher()

            let countString = searchModel.totalCountPublisher
                .combineLatest(searchModel.usersPublisher)
                .map { "\($1.count) / \($0)" }
                .eraseToAnyPublisher()

            let reloadData = searchModel.usersPublisher.map { _ in }
                .merge(with: searchModel.totalCountPublisher.map { _ in },
                       searchModel.isFetchingUsersPublisher.map { _ in })
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

            self.output = Output(
                users: searchModel.users,
                isFetchingUsers: searchModel.isFetchingUsers,
                accessTokenAlert: searchModel.errorMessage,
                updateLoadingView: updateLoadingView,
                selectedUser: selectedUser,
                keyboardWillShow: keyboardWillShow,
                keyboardWillHide: keyboardWillHide,
                countString: countString,
                reloadData: reloadData
            )
        }

        searchText
            .map { $0 ?? "" }
            .sink {
                searchModel.fetchUsers(withQuery: $0)
            }
            .store(in: &cancellables)

        isReachedBottom
            .removeDuplicates()
            .filter { $0 }
            .sink { _ in
                searchModel.fetchUsers()
            }
            .store(in: &cancellables)

        searchModel.usersPublisher
            .assign(to: \.users, on: output)
            .store(in: &cancellables)

        searchModel.isFetchingUsersPublisher
            .assign(to: \.isFetchingUsers, on: output)
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
    }

    final class Output {
        @Published
        fileprivate(set) var users: [User]
        @Published
        fileprivate(set) var isFetchingUsers: Bool
        let accessTokenAlert: AnyPublisher<ErrorMessage, Never>
        let updateLoadingView: AnyPublisher<(UIView, Bool), Never>
        let selectedUser: AnyPublisher<User, Never>
        let keyboardWillShow: AnyPublisher<UIKeyboardInfo, Never>
        let keyboardWillHide: AnyPublisher<UIKeyboardInfo, Never>
        let countString: AnyPublisher<String, Never>
        let reloadData: AnyPublisher<Void, Never>
        init(
            users: [User],
            isFetchingUsers: Bool,
            accessTokenAlert: AnyPublisher<ErrorMessage, Never>,
            updateLoadingView: AnyPublisher<(UIView, Bool), Never>,
            selectedUser: AnyPublisher<User, Never>,
            keyboardWillShow: AnyPublisher<UIKeyboardInfo, Never>,
            keyboardWillHide: AnyPublisher<UIKeyboardInfo, Never>,
            countString: AnyPublisher<String, Never>,
            reloadData: AnyPublisher<Void, Never>
        ) {
            self.users = users
            self.isFetchingUsers = isFetchingUsers
            self.accessTokenAlert = accessTokenAlert
            self.updateLoadingView = updateLoadingView
            self.selectedUser = selectedUser
            self.keyboardWillShow = keyboardWillShow
            self.keyboardWillHide = keyboardWillHide
            self.countString = countString
            self.reloadData = reloadData
        }
    }
}
