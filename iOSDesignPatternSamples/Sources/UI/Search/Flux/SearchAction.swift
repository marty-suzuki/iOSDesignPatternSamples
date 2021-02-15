//
//  SearchAction.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import Foundation
import GithubKit
import UIKit

protocol SearchActionType: AnyObject {
    func setlect(
        from user: [User],
        at indexPath: IndexPath
    )
    func isViewAppearing(_ isViewAppearing: Bool)
    func searchText(_ text: String?)
    func isReachedBottom(_ isReachedBottom: Bool)
    func headerFooterView(_ view: UIView)
    func load()
}

final class SearchAction: SearchActionType {
    private let dispatcher: SearchDispatcher

    private let _isViewAppearing = PassthroughSubject<Bool, Never>()
    private let _searchText = PassthroughSubject<String?, Never>()
    private let _isReachedBottom = PassthroughSubject<Bool, Never>()
    private let _headerFooterView = PassthroughSubject<UIView, Never>()
    private let _load = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(
        notificationCenter: NotificationCenter,
        dispatcher: SearchDispatcher,
        searchModel: SearchModelType
    ) {
        self.dispatcher = dispatcher

        func handleKeyboard(
            name: Notification.Name,
            subject: PassthroughSubject<UIKeyboardInfo, Never>
        ) -> Void {
            _isViewAppearing
                .map { isViewAppearing -> AnyPublisher<UIKeyboardInfo, Never> in
                    guard isViewAppearing else {
                        return Empty().eraseToAnyPublisher()
                    }
                    return notificationCenter.publisher(for: name)
                        .flatMap { notification -> AnyPublisher<UIKeyboardInfo, Never> in
                            guard let info = UIKeyboardInfo(notification: notification) else {
                                return Empty().eraseToAnyPublisher()
                            }
                            return Just(info).eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                }
                .switchToLatest()
                .sink(receiveValue: subject.send)
                .store(in: &cancellables)
        }

        handleKeyboard(
            name: UIResponder.keyboardWillShowNotification,
            subject: dispatcher.keyboardWillShow
        )

        handleKeyboard(
            name: UIResponder.keyboardWillHideNotification,
            subject: dispatcher.keyboardWillHide
        )

        _searchText
            .sink {
                guard let text = $0 else {
                    return
                }
                searchModel.fetchUsers(withQuery: text)
            }
            .store(in: &cancellables)

        searchModel.errorMessage
            .sink(receiveValue: dispatcher.accessTokenAlert.send)
            .store(in: &cancellables)

        _load
            .map { searchModel.isFetchingUsersPublisher }
            .switchToLatest()
            .sink(receiveValue: dispatcher.isFetchingUsers.send)
            .store(in: &cancellables)

        _load
            .map { searchModel.usersPublisher }
            .switchToLatest()
            .sink(receiveValue: dispatcher.users.send)
            .store(in: &cancellables)

        _load
            .map {
                searchModel.totalCountPublisher
                    .combineLatest(searchModel.usersPublisher)
            }
            .switchToLatest()
            .map { "\($1.count) / \($0)" }
            .sink(receiveValue: dispatcher.countString.send)
            .store(in: &cancellables)

        _isReachedBottom
            .removeDuplicates()
            .filter { $0 }
            .sink { _ in
                searchModel.fetchUsers()
            }
            .store(in: &cancellables)

        _headerFooterView
            .combineLatest(searchModel.isFetchingUsersPublisher)
            .sink(receiveValue: dispatcher.updateLoadingView.send)
            .store(in: &cancellables)
    }

    func setlect(
        from user: [User],
        at indexPath: IndexPath
    ) {
        let user = user[indexPath.row]
        dispatcher.selectedUser.send(user)
    }

    func isViewAppearing(_ isViewAppearing: Bool) {
        _isViewAppearing.send(isViewAppearing)
    }

    func searchText(_ text: String?) {
        _searchText.send(text)
    }

    func isReachedBottom(_ isReachedBottom: Bool) {
        _isReachedBottom.send(isReachedBottom)
    }

    func headerFooterView(_ view: UIView) {
        _headerFooterView.send(view)
    }

    func load() {
        _load.send()
    }
}
