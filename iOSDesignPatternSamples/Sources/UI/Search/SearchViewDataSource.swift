//
//  SearchViewDataSource.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import Foundation
import GithubKit
import UIKit

final class SearchViewDataSource: NSObject {
    let isReachedBottom: AnyPublisher<Bool, Never>
    let headerFooterView: AnyPublisher<UIView, Never>

    private let _isReachedBottom = PassthroughSubject<Bool, Never>()
    private let _headerFooterView = PassthroughSubject<UIView, Never>()

    private let store: UserStore
    private let action: UserAction

    init(flux: Flux) {
        self.action = flux.userAction
        self.store = flux.userStore
        self.isReachedBottom = _isReachedBottom.removeDuplicates().eraseToAnyPublisher()
        self.headerFooterView = _headerFooterView.eraseToAnyPublisher()
    }

    func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(UserViewCell.self)
        tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.className)
    }
}

extension SearchViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UserViewCell.self, for: indexPath)
        let user = store.users[indexPath.row]
        cell.configure(with: user)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: UITableViewHeaderFooterView.className) else {
            return nil
        }
        _headerFooterView.send(view)
        return view
    }
}

extension SearchViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let user = store.users[indexPath.row]
        action.selectUser(user)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let user = store.users[indexPath.row]
        return UserViewCell.calculateHeight(with: user, and: tableView)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return store.isUserFetching ? LoadingView.defaultHeight : .leastNormalMagnitude
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
        _isReachedBottom.send(maxScrollDistance <= scrollView.contentOffset.y)
    }
}
