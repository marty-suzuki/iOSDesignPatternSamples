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
    init(view: SearchView)
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
    private weak var view: SearchView?
    private var query: String = "" {
        didSet {
            if query != oldValue {
                users.removeAll()
                pageInfo = nil
                totalCount = 0
            }
            task?.cancel()
            task = nil
            fetchUsers()
        }
    }
    private var task: URLSessionTask? = nil
    private var pageInfo: PageInfo? = nil
    private var totalCount: Int = 0 {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let me = self else { return }
                me.view?.updateTotalCountLabel("\(me.users.count) / \(me.totalCount)")
                me.view?.reloadData()
            }
        }
    }
    private var users: [User] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let me = self else { return }
                me.view?.updateTotalCountLabel("\(me.users.count) / \(me.totalCount)")
                me.view?.reloadData()
            }
        }
    }
    private let debounce: (_ action: @escaping () -> ()) -> () = {
        var lastFireTime: DispatchTime = .now()
        let delay: DispatchTimeInterval = .milliseconds(500)
        return { [delay] action in
            let deadline: DispatchTime = .now() + delay
            lastFireTime = .now()
            DispatchQueue.global().asyncAfter(deadline: deadline) { [delay] in
                let now: DispatchTime = .now()
                let when: DispatchTime = lastFireTime + delay
                if now < when { return }
                lastFireTime = .now()
                DispatchQueue.main.async {
                    action()
                }
            }
        }
    }()
    private var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                fetchUsers()
            }
        }
    }
    private(set) var isFetchingUsers = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.view?.reloadData()
            }
        }
    }
    private var pool = NoticeObserverPool()
    
    var numberOfUsers: Int {
        return users.count
    }
    
    init(view: SearchView) {
        self.view = view
    }
    
    private func fetchUsers() {
        if query.isEmpty || task != nil { return }
        if let pageInfo = pageInfo, !pageInfo.hasNextPage || pageInfo.endCursor == nil { return }
        isFetchingUsers = true
        let request = SearchUserRequest(query: query, after: pageInfo?.endCursor)
        self.task = ApiSession.shared.send(request) { [weak self] in
            switch $0 {
            case .success(let value):
                self?.pageInfo = value.pageInfo
                self?.users.append(contentsOf: value.nodes)
                self?.totalCount = value.totalCount
            
            case .failure(let error):
                if case .emptyToken? = (error as? ApiSession.Error) {
                    DispatchQueue.main.async {
                        self?.view?.showEmptyTokenError()
                    }
                }
            }
            self?.isFetchingUsers = false
            self?.task = nil
        }
    }
    
    func search(queryIfNeeded qeury: String) {
        debounce { [weak self] in
            self?.query = qeury
        }
    }
    
    func user(at index: Int) -> User {
        return users[index]
    }
    
    func showUser(at index: Int) {
        let user = users[index]
        view?.showUserRepository(with: user)
    }
    
    func setIsReachedBottom(_ isReachedBottom: Bool) {
        self.isReachedBottom = isReachedBottom
    }
    
    func viewWillAppear() {
        UIKeyboardWillShow.observe { [weak self] in
            self?.view?.keyboardWillShow(with: $0)
        }
        .disposed(by: pool)
        
        UIKeyboardWillHide.observe { [weak self] in
            self?.view?.keyboardWillHide(with: $0)
        }
        .disposed(by: pool)
    }
    
    func viewWillDisappear() {
        pool = NoticeObserverPool()
    }
    
    func showLoadingView(on view: UIView) {
        self.view?.updateLoadingView(with: view, isLoading: isFetchingUsers)
    }
}
