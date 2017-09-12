//
//  SearchViewDataSource.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import UIKit
import GithubKit
import RxSwift

final class SearchViewDataSource: NSObject {
    let isReachedBottom: Observable<Bool>
    let headerFooterView: Observable<UIView>

    private let _isReachedBottom = PublishSubject<Bool>()
    private let _headerFooterView = PublishSubject<UIView>()

    private let store: UserStore
    private let action: UserAction

    init(action: UserAction = .init(), store: UserStore = .instantiate()) {
        self.action = action
        self.store = store
        self.isReachedBottom = _isReachedBottom.distinctUntilChanged()
        self.headerFooterView = _headerFooterView
    }
    
    func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.registerCell(UserViewCell.self)
        tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.className)
    }
}

extension SearchViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.usersValue.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(UserViewCell.self, for: indexPath)
        let user = store.usersValue[indexPath.row]
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
        _headerFooterView.onNext(view)
        return view
    }
}

extension SearchViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let user = store.usersValue[indexPath.row]
        action.selectUser(user)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let user = store.usersValue[indexPath.row]
        return UserViewCell.calculateHeight(with: user, and: tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return store.isUserFetchingValue ? LoadingView.defaultHeight : .leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
        _isReachedBottom.onNext(maxScrollDistance <= scrollView.contentOffset.y)
    }
}
