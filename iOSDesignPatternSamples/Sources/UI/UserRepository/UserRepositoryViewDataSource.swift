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
<<<<<<< HEAD
    let isReachedBottom: Observable<Bool>
    let headerFooterView: Observable<UIView>

    private let _isReachedBottom = PublishRelay<Bool>()
    private let _headerFooterView = PublishRelay<UIView>()

    private let action: RepositoryAction
    private let store: RepositoryStore

    init(action: RepositoryAction = .init(), store: RepositoryStore = .instantiate()) {
        self.action = action
        self.store = store
        self.isReachedBottom = _isReachedBottom.distinctUntilChanged()
        self.headerFooterView = _headerFooterView.asObservable()
=======

    private let viewModel: UserRepositoryViewModel
    
    init(viewModel: UserRepositoryViewModel) {
        self.viewModel = viewModel
>>>>>>> mvvm
    }
    
    func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(RepositoryViewCell.self)
        tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.className)
    }
}

extension UserRepositoryViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
<<<<<<< HEAD
        return store.value.repositories.count
=======
        return viewModel.repositories.count
>>>>>>> mvvm
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(RepositoryViewCell.self, for: indexPath)
<<<<<<< HEAD
        let repository = store.value.repositories[indexPath.row]
=======
        let repository = viewModel.repositories[indexPath.row]
>>>>>>> mvvm
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
<<<<<<< HEAD
        _headerFooterView.accept(view)
=======
        viewModel.input.headerFooterView.onNext(view)
>>>>>>> mvvm
        return view
    }
}

extension UserRepositoryViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
<<<<<<< HEAD
        let repository = store.value.repositories[indexPath.row]
        action.selectRepository(repository)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let repository = store.value.repositories[indexPath.row]
=======
        viewModel.input.selectedIndexPath.onNext(indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let repository = viewModel.repositories[indexPath.row]
>>>>>>> mvvm
        return RepositoryViewCell.calculateHeight(with: repository, and: tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
<<<<<<< HEAD
        return store.value.isRepositoryFetching ? LoadingView.defaultHeight : .leastNormalMagnitude
=======
        return viewModel.isFetchingRepositories ? LoadingView.defaultHeight : .leastNormalMagnitude
>>>>>>> mvvm
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
<<<<<<< HEAD
        _isReachedBottom.accept(maxScrollDistance <= scrollView.contentOffset.y)
=======
       viewModel.input.isReachedBottom.onNext(maxScrollDistance <= scrollView.contentOffset.y)
>>>>>>> mvvm
    }
}
