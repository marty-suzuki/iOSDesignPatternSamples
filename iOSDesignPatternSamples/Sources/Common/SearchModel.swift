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

protocol SearchModelDelegate: AnyObject {
    func searchModel(_ searchModel: SearchModel, didRecieve errorMessage: ErrorMessage)
    func searchModel(_ searchModel: SearchModel, didChange isFetchingUsers: Bool)
    func searchModel(_ searchModel: SearchModel, didChange users: [User])
    func searchModel(_ searchModel: SearchModel, didChange totalCount: Int)
}

struct ErrorMessage {
    let title: String
    let message: String
}

protocol SearchModelType: AnyObject {
    var delegate: SearchModelDelegate? { get set }
    var query: String { get }
    var totalCount: Int { get }
    var users: [User] { get }
    var isFetchingUsers: Bool { get }
    func fetchUsers()
    func fetchUsers(withQuery query: String)
}

final class SearchModel: SearchModelType {

    weak var delegate: SearchModelDelegate?

    private(set) var query: String = ""
    private(set) var totalCount: Int = 0 {
        didSet {
            delegate?.searchModel(self, didChange: totalCount)
        }
    }
    private(set) var users: [User] = [] {
        didSet {
            delegate?.searchModel(self, didChange: users)
        }
    }
    private(set) var isFetchingUsers = false {
        didSet {
            delegate?.searchModel(self, didChange: isFetchingUsers)
        }
    }

    private var pageInfo: PageInfo?
    private var cancellable: AnyCancellable?

    private lazy var debounce: (_ action: @escaping () -> ()) -> () = {
        var lastFireTime: DispatchTime = .now()
        let delay: DispatchTimeInterval = .milliseconds(500)
        return { [delay, asyncAfter] action in
            let deadline: DispatchTime = .now() + delay
            lastFireTime = .now()
            asyncAfter(deadline) { [delay] in
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

    private let sendRequest: SendRequest<SearchUserRequest>
    private let asyncAfter: (DispatchTime, @escaping @convention(block) () -> Void) -> Void

    init(
        sendRequest: @escaping SendRequest<SearchUserRequest>,
        asyncAfter: @escaping (DispatchTime, @escaping @convention(block) () -> Void) -> Void
    ) {
        self.sendRequest = sendRequest
        self.asyncAfter = asyncAfter
    }

    func fetchUsers() {
        if query.isEmpty || cancellable != nil { return }
        if let pageInfo = pageInfo, !pageInfo.hasNextPage || pageInfo.endCursor == nil { return }
        isFetchingUsers = true
        let request = SearchUserRequest(query: query, after: pageInfo?.endCursor)
        self.cancellable = sendRequest(request) { [weak self] in
            guard let me = self else {
                return
            }

            switch $0 {
            case .success(let value):
                me.pageInfo = value.pageInfo
                me.users.append(contentsOf: value.nodes)
                me.totalCount = value.totalCount

            case .failure(let error):
                if case .emptyToken? = (error as? ApiSession.Error) {
                    let title = "Access Token Error"
                    let message = "\"Github Personal Access Token\" is Required.\n Please set it in ApiSession.extension.swift!"
                    let errorMessage = ErrorMessage(title: title, message: message)
                    me.delegate?.searchModel(me, didRecieve: errorMessage)
                }
            }

            me.isFetchingUsers = false
            me.cancellable = nil
        }
    }

    func fetchUsers(withQuery query: String) {
        debounce { [weak self] in
            guard let me = self else {
                return
            }

            let oldValue = me.query
            me.query = query
            if query != oldValue {
                me.users.removeAll()
                me.pageInfo = nil
                me.totalCount = 0
            }
            me.cancellable?.cancel()
            me.cancellable = nil
            me.fetchUsers()
        }
    }
}
