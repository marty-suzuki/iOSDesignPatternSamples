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
    @Published
    private var query: String?

    private var cancellable = Set<AnyCancellable>()

    private let _fetchUsers = PassthroughSubject<Void, Never>()
    private let _feachUsersWithQuery = PassthroughSubject<String, Never>()

    init(
        sendRequest: @escaping SendRequest<SearchUserRequest>
    ) {
        let _errorMessage = PassthroughSubject<ErrorMessage, Never>()
        self.errorMessage = _errorMessage.eraseToAnyPublisher()

        let pageInfo = $pageInfo

        let query = $query
            .map { $0 ?? "" }

        let initialLoad = query
            .filter { !$0.isEmpty }
            .flatMap { query in
                pageInfo
                    .map { (query, $0) }
                    .prefix(1)
            }

        let loadMore = _fetchUsers
            .flatMap { _ in
                query
                    .combineLatest(pageInfo)
                    .prefix(1)
            }
            .filter { !$0.isEmpty && $1 != nil }

        _feachUsersWithQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] in
                self?.pageInfo = nil
                self?.users = []
                self?.totalCount = 0
                self?.query = $0
            }
            .store(in: &cancellable)

        let requestWillStart = initialLoad.merge(with: loadMore)
            .flatMap { query, pageInfo -> AnyPublisher<SearchUserRequest, Never> in
                if let pageInfo = pageInfo, !pageInfo.hasNextPage {
                    return Empty().eraseToAnyPublisher()
                }
                let request = SearchUserRequest(query: query, after: pageInfo?.endCursor)
                return Just(request).eraseToAnyPublisher()
            }
            .removeDuplicates { $0.query == $1.query && $0.after == $1.after }

        requestWillStart
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isFetchingUsers = true
            })
            .flatMap { request -> AnyPublisher<Result<Response<User>, Error>, Never> in
                sendRequest(request)
                    .map { response in
                        Result<Response<User>, Error>.success(response)
                    }
                    .catch { error in
                        Just(Result<Response<User>, Error>.failure(error))
                    }
                    .prefix(1)
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isFetchingUsers = false
            })
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
