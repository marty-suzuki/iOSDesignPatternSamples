//
//  UserRepositoryViewDataSource.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import UIKit
import GithubKit
import RxSwift
import RxCocoa

final class UserRepositoryViewDataSource: NSObject {
    let isReachedBottom: Observable<Bool>
    let headerFooterView: Observable<UIView>

    private let _isReachedBottom = PublishSubject<Bool>()
    private let _headerFooterView = PublishSubject<UIView>()

    private let action: RepositoryAction
    private let store: RepositoryStore

    init(action: RepositoryAction = .init(), store: RepositoryStore = .instantiate()) {
        self.action = action
        self.store = store
        self.isReachedBottom = _isReachedBottom.distinctUntilChanged()
        self.headerFooterView = _headerFooterView
    }
    
    func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.registerCell(RepositoryViewCell.self)
        tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.className)
    }
}

extension UserRepositoryViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.repositoriesValue.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(RepositoryViewCell.self, for: indexPath)
        let repository = store.repositoriesValue[indexPath.row]
        cell.configure(with: repository)
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

extension UserRepositoryViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let repository = store.repositoriesValue[indexPath.row]
        action.selectRepository(repository)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let repository = store.repositoriesValue[indexPath.row]
        return RepositoryViewCell.calculateHeight(with: repository, and: tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return store.isRepositoryFetchingValue ? LoadingView.defaultHeight : .leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
        _isReachedBottom.onNext(maxScrollDistance <= scrollView.contentOffset.y)
    }
}
