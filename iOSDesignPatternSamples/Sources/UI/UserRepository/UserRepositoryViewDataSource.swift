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
    private let selectedIndexPath: AnyObserver<IndexPath>
    private let isReachedBottom: AnyObserver<Bool>
    private let headerFooterView: AnyObserver<UIView>

    private let viewModel: UserRepositoryViewModel
    
    init(viewModel: UserRepositoryViewModel,
         selectedIndexPath: AnyObserver<IndexPath>,
         isReachedBottom: AnyObserver<Bool>,
         headerFooterView: AnyObserver<UIView>) {
        self.viewModel = viewModel
        self.selectedIndexPath = selectedIndexPath
        self.isReachedBottom = isReachedBottom
        self.headerFooterView = headerFooterView
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
        return viewModel.value.repositories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(RepositoryViewCell.self, for: indexPath)
        let repository = viewModel.value.repositories[indexPath.row]
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
        headerFooterView.onNext(view)
        return view
    }
}

extension UserRepositoryViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        selectedIndexPath.onNext(indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let repository = viewModel.value.repositories[indexPath.row]
        return RepositoryViewCell.calculateHeight(with: repository, and: tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return viewModel.value.isFetchingRepositories ? LoadingView.defaultHeight : .leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
        isReachedBottom.onNext(maxScrollDistance <= scrollView.contentOffset.y)
    }
}
