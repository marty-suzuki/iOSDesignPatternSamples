//
//  SearchModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2019/03/01.
//  Copyright © 2019 marty-suzuki. All rights reserved.
//

import GithubKit

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

final class SearchModel {

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
    private var task: URLSessionTask?

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

    func fetchUsers() {
        if query.isEmpty || task != nil { return }
        if let pageInfo = pageInfo, !pageInfo.hasNextPage || pageInfo.endCursor == nil { return }
        isFetchingUsers = true
        let request = SearchUserRequest(query: query, after: pageInfo?.endCursor)
        self.task = ApiSession.shared.send(request) { [weak self] in
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
            me.task = nil
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
            me.task?.cancel()
            me.task = nil
            me.fetchUsers()
        }
    }
}
