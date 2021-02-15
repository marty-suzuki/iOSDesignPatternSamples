//
//  SearchStore.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import Foundation
import GithubKit
import UIKit

protocol SearchStoreType: AnyObject {
    var users: [User] { get }
    var isFetchingUsers: Bool { get }
    var countStringPublisher: Published<String>.Publisher { get }
    var selectedUser: AnyPublisher<User, Never> { get }
    var reloadData: AnyPublisher<Void, Never> { get }
    var updateLoadingView: AnyPublisher<(UIView, Bool), Never> { get }
    var keyboardWillShow: AnyPublisher<UIKeyboardInfo, Never> { get }
    var keyboardWillHide: AnyPublisher<UIKeyboardInfo, Never> { get }
    var accessTokenAlert: AnyPublisher<ErrorMessage, Never> { get }
}

final class SearchStore: SearchStoreType {
    @Published
    private(set) var users: [User] = []
    @Published
    private(set) var isFetchingUsers = false
    @Published
    private(set) var countString: String = ""

    var countStringPublisher: Published<String>.Publisher {
        $countString
    }

    let selectedUser: AnyPublisher<User, Never>
    let reloadData: AnyPublisher<Void, Never>
    let updateLoadingView: AnyPublisher<(UIView, Bool), Never>
    let keyboardWillShow: AnyPublisher<UIKeyboardInfo, Never>
    let keyboardWillHide: AnyPublisher<UIKeyboardInfo, Never>
    let accessTokenAlert: AnyPublisher<ErrorMessage, Never>

    private var cancellables = Set<AnyCancellable>()

    init(
        dispatcher: SearchDispatcher
    ) {
        self.selectedUser = dispatcher.selectedUser
            .eraseToAnyPublisher()
        self.updateLoadingView = dispatcher.updateLoadingView
            .eraseToAnyPublisher()
        self.keyboardWillHide = dispatcher.keyboardWillHide
            .eraseToAnyPublisher()
        self.keyboardWillShow = dispatcher.keyboardWillShow
            .eraseToAnyPublisher()
        self.accessTokenAlert = dispatcher.accessTokenAlert
            .eraseToAnyPublisher()
        let reloadData = PassthroughSubject<Void, Never>()
        self.reloadData = reloadData.eraseToAnyPublisher()

        dispatcher.countString
            .assign(to: \.countString, on: self)
            .store(in: &cancellables)

        dispatcher.isFetchingUsers
            .assign(to: \.isFetchingUsers, on: self)
            .store(in: &cancellables)

        dispatcher.users
            .assign(to: \.users, on: self)
            .store(in: &cancellables)

        $users
            .map { _ in }
            .merge(with: $isFetchingUsers.map { _ in })
            .sink(receiveValue: reloadData.send)
            .store(in: &cancellables)
    }
}
