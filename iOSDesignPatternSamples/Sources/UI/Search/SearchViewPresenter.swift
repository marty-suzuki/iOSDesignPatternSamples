//
//  SearchViewPresenter.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit
import NoticeObserveKit

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

    private let model = SearchModel()
    private var isReachedBottom: Bool = false
    private var pool = Notice.ObserverPool()

    init() {
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
        NotificationCenter.default.nok.observe(name: .keyboardWillShow) { [weak self] in
            self?.view?.keyboardWillShow(with: $0)
        }
        .invalidated(by: pool)

        NotificationCenter.default.nok.observe(name: .keyboardWillHide) { [weak self] in
            self?.view?.keyboardWillHide(with: $0)
        }
        .invalidated(by: pool)
    }
    
    func viewWillDisappear() {
        pool = Notice.ObserverPool()
    }
    
    func showLoadingView(on view: UIView) {
        self.view?.updateLoadingView(with: view, isLoading: isFetchingUsers)
    }
}

extension SearchViewPresenter: SearchModelDelegate {
    func searchModel(_ searchModel: SearchModel, didRecieve errorMessage: ErrorMessage) {
        DispatchQueue.main.async {
            self.view?.showEmptyTokenError(errorMessage: errorMessage)
        }
    }

    func searchModel(_ searchModel: SearchModel, didChange isFetchingUsers: Bool) {
        DispatchQueue.main.async {
            self.view?.reloadData()
        }
    }

    func searchModel(_ searchModel: SearchModel, didChange users: [User]) {
        let totalCount = searchModel.totalCount
        DispatchQueue.main.async {
            self.view?.updateTotalCountLabel("\(users.count) / \(totalCount)")
            self.view?.reloadData()
        }
    }

    func searchModel(_ searchModel: SearchModel, didChange totalCount: Int) {
        let users = searchModel.users
        DispatchQueue.main.async {
            self.view?.updateTotalCountLabel("\(users.count) / \(totalCount)")
            self.view?.reloadData()
        }
    }
}
