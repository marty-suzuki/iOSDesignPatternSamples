//
//  RepositoryModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2019/03/01.
//  Copyright © 2019 marty-suzuki. All rights reserved.
//

import GithubKit

protocol RepositoryModelDelegate: AnyObject {
    func repositoryModel(_ repositoryModel: RepositoryModel, didChange isFetchingRepositories: Bool)
    func repositoryModel(_ repositoryModel: RepositoryModel, didChange repositories: [Repository])
    func repositoryModel(_ repositoryModel: RepositoryModel, didChange totalCount: Int)
}

final class RepositoryModel {

    let user: User
    weak var delegate: RepositoryModelDelegate?

    private(set) var query: String = ""
    private(set) var totalCount: Int = 0 {
        didSet {
            delegate?.repositoryModel(self, didChange: totalCount)
        }
    }
    private(set) var repositories: [Repository] = [] {
        didSet {
            delegate?.repositoryModel(self, didChange: repositories)
        }
    }
    private(set) var isFetchingRepositories = false {
        didSet {
            delegate?.repositoryModel(self, didChange: isFetchingRepositories)
        }
    }

    private var pageInfo: PageInfo?
    private var task: URLSessionTask?

    init(user: User) {
        self.user = user
    }

    func fetchRepositories() {
        if task != nil { return }
        if let pageInfo = pageInfo, !pageInfo.hasNextPage || pageInfo.endCursor == nil { return }
        isFetchingRepositories = true
        let request = UserNodeRequest(id: user.id, after: pageInfo?.endCursor)
        self.task = ApiSession.shared.send(request) { [weak self] in
            guard let me = self else {
                return
            }

            switch $0 {
            case .success(let value):
                me.pageInfo = value.pageInfo
                me.repositories.append(contentsOf: value.nodes)
                me.totalCount = value.totalCount

            case .failure(let error):
                print(error)
            }

            me.isFetchingRepositories = false
            me.task = nil
        }
    }
}
