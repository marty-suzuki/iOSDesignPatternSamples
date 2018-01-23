//
//  UserRepositoryViewPresenter.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit

protocol UserRepositoryPresenter: class {
    init(user: User)
    weak var view: UserRepositoryView? { get set }
    var title: String { get }
    var isFetchingRepositories: Bool { get }
    var numberOfRepositories: Int { get }
    func repository(at index: Int) -> Repository
    func showRepository(at index: Int)
    func showLoadingView(on view: UIView)
    func setIsReachedBottom(_ isReachedBottom: Bool)
    func fetchRepositories()
}

final class UserRepositoryViewPresenter: UserRepositoryPresenter {
    weak var view: UserRepositoryView?
    private let user: User
    
    private var pageInfo: PageInfo? = nil
    private var task: URLSessionTask? = nil
    private var repositories: [Repository] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let me = self else { return }
                me.view?.updateTotalCountLabel("\(me.repositories.count) / \(me.totalCount)")
                me.view?.reloadData()
            }
        }
    }
    private var totalCount: Int = 0  {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let me = self else { return }
                me.view?.updateTotalCountLabel("\(me.repositories.count) / \(me.totalCount)")
                me.view?.reloadData()
            }
        }
    }
    private(set) var isFetchingRepositories = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.view?.reloadData()
            }
        }
    }
    private var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                fetchRepositories()
            }
        }
    }
    
    var numberOfRepositories: Int {
        return repositories.count
    }
    var title: String {
        return "\(user.login)'s Repositories"
    }
    
    init(user: User) {
        self.user = user
    }
    
    func fetchRepositories() {
        if task != nil { return }
        if let pageInfo = pageInfo, !pageInfo.hasNextPage || pageInfo.endCursor == nil { return }
        isFetchingRepositories = true
        let request = UserNodeRequest(id: user.id, after: pageInfo?.endCursor)
        self.task = ApiSession.shared.send(request) { [weak self] in
            switch $0 {
            case .success(let value):
                    self?.pageInfo = value.pageInfo
                    self?.repositories.append(contentsOf: value.nodes)
                    self?.totalCount = value.totalCount
            case .failure(let error):
                print(error)
            }
            self?.isFetchingRepositories = false
            self?.task = nil
        }
    }
    
    func repository(at index: Int) -> Repository {
        return repositories[index]
    }
    
    func showRepository(at index: Int) {
        let repository = repositories[index]
        view?.showRepository(with: repository)
    }
    
    func showLoadingView(on view: UIView) {
        self.view?.updateLoadingView(with: view, isLoading: isFetchingRepositories)
    }
    
    func setIsReachedBottom(_ isReachedBottom: Bool) {
        self.isReachedBottom = isReachedBottom
    }
}
