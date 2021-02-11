//
//  SearchViewPresenter.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import Foundation
import GithubKit
import UIKit

protocol SearchPresenter: class {
    var view: SearchView? { get set }
    var numberOfUsers: Int { get }
    var isFetchingUsers: Bool { get }
    func search(queryIfNeeded qeury: String)
    func user(at index: Int) -> User
    func showUser(at index: Int)
    func setIsReachedBottom(_ isReachedBottom: Bool)
    func viewWillAppear()
    func viewWillDisappear()
    func showLoadingView(on view: UIView)
}

final class SearchViewPresenter: SearchPresenter {
    weak var view: SearchView?
    
    var numberOfUsers: Int {
        return model.users.count
    }

    var isFetchingUsers: Bool {
        return model.isFetchingUsers
    }

    private let model: SearchModelType
    private let mainAsync: (@escaping () -> Void) -> Void
    private let notificationCenter: NotificationCenter

    private var isReachedBottom: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init(
        model: SearchModelType,
        mainAsync: @escaping (@escaping () -> Void) -> Void,
        notificationCenter: NotificationCenter
    ) {
        self.model = model
        self.mainAsync = mainAsync
        self.notificationCenter = notificationCenter
        self.model.delegate = self
    }
    
    private func fetchUsers() {
        model.fetchUsers()
    }
    
    func search(queryIfNeeded query: String) {
        model.fetchUsers(withQuery: query)
    }
    
    func user(at index: Int) -> User {
        return model.users[index]
    }
    
    func showUser(at index: Int) {
        let user = model.users[index]
        view?.showUserRepository(with: user)
    }
    
    func setIsReachedBottom(_ isReachedBottom: Bool) {
        let oldValue = self.isReachedBottom
        self.isReachedBottom = isReachedBottom
        if isReachedBottom && isReachedBottom != oldValue {
            fetchUsers()
        }
    }
    
    func viewWillAppear() {
        notificationCenter.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                guard let info = UIKeyboardInfo(notification: notification) else {
                    return
                }
                self?.view?.keyboardWillShow(with: info)
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                guard let info = UIKeyboardInfo(notification: notification) else {
                    return
                }
                self?.view?.keyboardWillHide(with: info)
            }
            .store(in: &cancellables)
    }
    
    func viewWillDisappear() {
        cancellables.removeAll()
    }
    
    func showLoadingView(on view: UIView) {
        self.view?.updateLoadingView(with: view, isLoading: isFetchingUsers)
    }
}

extension SearchViewPresenter: SearchModelDelegate {
    func searchModel(_ searchModel: SearchModel, didRecieve errorMessage: ErrorMessage) {
        mainAsync {
            self.view?.showEmptyTokenError(errorMessage: errorMessage)
        }
    }

    func searchModel(_ searchModel: SearchModel, didChange isFetchingUsers: Bool) {
        mainAsync {
            self.view?.reloadData()
        }
    }

    func searchModel(_ searchModel: SearchModel, didChange users: [User]) {
        let totalCount = searchModel.totalCount
        mainAsync {
            self.view?.updateTotalCountLabel("\(users.count) / \(totalCount)")
            self.view?.reloadData()
        }
    }

    func searchModel(_ searchModel: SearchModel, didChange totalCount: Int) {
        let users = searchModel.users
        mainAsync {
            self.view?.updateTotalCountLabel("\(users.count) / \(totalCount)")
            self.view?.reloadData()
        }
    }
}
