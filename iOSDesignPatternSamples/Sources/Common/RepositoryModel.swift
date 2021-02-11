//
//  RepositoryModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2019/03/01.
//  Copyright © 2019 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit

protocol RepositoryModelDelegate: AnyObject {
    func repositoryModel(_ repositoryModel: RepositoryModel, didChange isFetchingRepositories: Bool)
    func repositoryModel(_ repositoryModel: RepositoryModel, didChange repositories: [Repository])
    func repositoryModel(_ repositoryModel: RepositoryModel, didChange totalCount: Int)
}

protocol RepositoryModelType: AnyObject {
    var user: User { get }
    var delegate: RepositoryModelDelegate? { get set }
    var query: String { get }
    var totalCount: Int { get }
    var repositories: [Repository] { get }
    var isFetchingRepositories: Bool { get }
    func fetchRepositories()
}

final class RepositoryModel: RepositoryModelType {

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
    private var cancellable: AnyCancellable?
    private let sendRequest: SendRequest<UserNodeRequest>

    init(
        user: User,
        sendRequest: @escaping SendRequest<UserNodeRequest>
    ) {
        self.user = user
        self.sendRequest = sendRequest
    }

    func fetchRepositories() {
        if cancellable != nil { return }
        if let pageInfo = pageInfo, !pageInfo.hasNextPage || pageInfo.endCursor == nil { return }
        isFetchingRepositories = true
        let request = UserNodeRequest(id: user.id, after: pageInfo?.endCursor)
        self.cancellable = sendRequest(request) { [weak self] in
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
            me.cancellable = nil
        }
    }
}
