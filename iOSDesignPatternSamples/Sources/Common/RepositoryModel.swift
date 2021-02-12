//
//  RepositoryModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2019/03/01.
//  Copyright © 2019 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit

protocol RepositoryModelType: AnyObject {
    var repositoriesPublisher: Published<[Repository]>.Publisher { get }
    var isFetchingRepositoriesPublisher: Published<Bool>.Publisher { get }
    var totalCountPublisher: Published<Int>.Publisher { get }
    var repositories: [Repository] { get }
    var isFetchingRepositories: Bool { get }
    func fetchRepositories()
}

final class RepositoryModel: RepositoryModelType {

    var repositoriesPublisher: Published<[Repository]>.Publisher {
        $repositories
    }
    var isFetchingRepositoriesPublisher: Published<Bool>.Publisher {
        $isFetchingRepositories
    }
    var totalCountPublisher: Published<Int>.Publisher {
        $totalCount
    }

    @Published
    private(set) var repositories: [Repository] = []
    @Published
    private(set) var isFetchingRepositories = false
    @Published
    private var totalCount = 0
    @Published
    private var pageInfo: PageInfo?

    private var cancellables = Set<AnyCancellable>()

    private let _fetchRepositories = PassthroughSubject<Void, Never>()

    init(user: User) {
        let requestTrigger = $pageInfo
            .map { (user, $0?.endCursor) }

        let initialLoadRequest = _fetchRepositories
            .map { _ -> AnyPublisher<(User, String?), Never> in
                requestTrigger
                    .prefix(1)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .filter { $1 == nil }

        let loadMoreRequest = _fetchRepositories
            .map { _ -> AnyPublisher<(User, String?), Never> in
                requestTrigger
                    .prefix(1)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .filter { $1 != nil }

        let willStartRequest = initialLoadRequest
            .merge(with: loadMoreRequest)
            .map { UserNodeRequest(id: $0.id, after: $1) }
            .removeDuplicates { $0.id == $1.id && $0.after == $1.after }

        willStartRequest
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isFetchingRepositories = true
            })
            .flatMap { request -> AnyPublisher<Response<Repository>, Never> in
                ApiSession.shared.send(request)
                    .catch { _ -> AnyPublisher<Response<Repository>, Never> in
                        Empty().eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isFetchingRepositories = false
            })
            .sink { [weak self] response in
                guard let me = self else {
                    return
                }
                me.pageInfo = response.pageInfo
                me.repositories = me.repositories + response.nodes
                me.totalCount = response.totalCount
            }
            .store(in: &cancellables)
    }

    func fetchRepositories() {
        _fetchRepositories.send()
    }
}
