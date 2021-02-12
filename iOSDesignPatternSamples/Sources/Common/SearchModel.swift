//
//  SearchModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2019/03/01.
//  Copyright © 2019 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit
import Foundation

struct ErrorMessage {
    let title: String
    let message: String
}

protocol SearchModelType: AnyObject {
    var errorMessage: AnyPublisher<ErrorMessage, Never> { get }
    var usersPublisher: Published<[User]>.Publisher { get }
    var isFetchingUsersPublisher: Published<Bool>.Publisher { get }
    var totalCountPublisher: Published<Int>.Publisher { get }
    var users: [User] { get }
    var isFetchingUsers: Bool { get }
    func fetchUsers()
    func fetchUsers(withQuery query: String)
}

final class SearchModel: SearchModelType {
    let errorMessage: AnyPublisher<ErrorMessage, Never>

    var usersPublisher: Published<[User]>.Publisher {
        $users
    }
    var isFetchingUsersPublisher: Published<Bool>.Publisher {
        $isFetchingUsers
    }
    var totalCountPublisher: Published<Int>.Publisher {
        $totalCount
    }

    @Published
    private(set) var users: [User] = []
    @Published
    private(set) var isFetchingUsers = false
    @Published
    private var totalCount = 0
    @Published
    private var pageInfo: PageInfo?

    private var cancellable = Set<AnyCancellable>()

    private let _fetchUsers = PassthroughSubject<Void, Never>()
    private let _feachUsersWithQuery = PassthroughSubject<String, Never>()

    init() {
        let _errorMessage = PassthroughSubject<ErrorMessage, Never>()
        self.errorMessage = _errorMessage.eraseToAnyPublisher()

        let query = _feachUsersWithQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()

        let endCousor = $pageInfo
            .map { $0?.endCursor }

        let initialLoad = query
            .filter { !$0.isEmpty }
            .flatMap { query in
                endCousor
                    .map { (query, $0) }
                    .prefix(1)
            }

        let loadMore = _fetchUsers
            .map { _ -> AnyPublisher<(String, String?), Never> in
                query
                    .combineLatest(endCousor)
                    .prefix(1)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .filter { !$0.isEmpty && $1 != nil }

        query
            .sink { [weak self] _ in
                self?.pageInfo = nil
                self?.users = []
                self?.totalCount = 0
            }
            .store(in: &cancellable)

        let requestWillStart = initialLoad.merge(with: loadMore)
            .map { SearchUserRequest(query: $0, after: $1) }
            .removeDuplicates { $0.query == $1.query && $0.after == $1.after }

        let response = requestWillStart
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isFetchingUsers = true
            })
            .map { request -> AnyPublisher<Result<Response<User>, Error>, Never> in
                ApiSession.shared.send(request)
                    .map { response in
                        Result<Response<User>, Error>.success(response)
                    }
                    .catch { error in
                        Just(Result<Response<User>, Error>.failure(error))
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isFetchingUsers = false
            })

        response
            .sink { [weak self] result in
                guard let me = self else {
                    return
                }
                switch result {
                case let .success(response):
                    me.pageInfo = response.pageInfo
                    me.users = me.users + response.nodes
                    me.totalCount = response.totalCount
                case let .failure(error):
                    guard case .emptyToken? = (error as? ApiSession.Error) else {
                        return
                    }
                    let title = "Access Token Error"
                    let message = "\"Github Personal Access Token\" is Required.\n Please set it in ApiSession.extension.swift!"
                    _errorMessage.send(ErrorMessage(title: title, message: message))
                }
            }
            .store(in: &cancellable)
    }

    func fetchUsers(withQuery query: String) {
        _feachUsersWithQuery.send(query)
    }

    func fetchUsers() {
        _fetchUsers.send()
    }
}
