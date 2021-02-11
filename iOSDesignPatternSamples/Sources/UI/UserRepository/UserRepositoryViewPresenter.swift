//
//  UserRepositoryViewPresenter.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit
import UIKit

protocol UserRepositoryPresenter: class {
    var view: UserRepositoryView? { get set }
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
    
    var numberOfRepositories: Int {
        return model.repositories.count
    }

    var isFetchingRepositories: Bool {
        return model.isFetchingRepositories
    }

    var title: String {
        return "\(model.user.login)'s Repositories"
    }

    private let model: RepositoryModel
    private var isReachedBottom: Bool = false
    
    init(user: User) {
        self.model = RepositoryModel(user: user, sendRequest: ApiSession.shared.send)
        self.model.delegate = self
    }
    
    func fetchRepositories() {
        model.fetchRepositories()
    }
    
    func repository(at index: Int) -> Repository {
        return model.repositories[index]
    }
    
    func showRepository(at index: Int) {
        let repository = model.repositories[index]
        view?.showRepository(with: repository)
    }
    
    func showLoadingView(on view: UIView) {
        self.view?.updateLoadingView(with: view, isLoading: isFetchingRepositories)
    }
    
    func setIsReachedBottom(_ isReachedBottom: Bool) {
        let oldValue = self.isReachedBottom
        self.isReachedBottom = isReachedBottom
        if isReachedBottom && isReachedBottom != oldValue {
            fetchRepositories()
        }
    }
}

extension UserRepositoryViewPresenter: RepositoryModelDelegate {
    func repositoryModel(_ repositoryModel: RepositoryModel, didChange isFetchingRepositories: Bool) {
        DispatchQueue.main.async {
            self.view?.reloadData()
        }
    }

    func repositoryModel(_ repositoryModel: RepositoryModel, didChange repositories: [Repository]) {
        let totalCount = repositoryModel.totalCount
        DispatchQueue.main.async {
            self.view?.updateTotalCountLabel("\(repositories.count) / \(totalCount)")
            self.view?.reloadData()
        }
    }

    func repositoryModel(_ repositoryModel: RepositoryModel, didChange totalCount: Int) {
        let repositories = repositoryModel.repositories
        DispatchQueue.main.async {
            self.view?.updateTotalCountLabel("\(repositories.count) / \(totalCount)")
            self.view?.reloadData()
        }
    }
}
