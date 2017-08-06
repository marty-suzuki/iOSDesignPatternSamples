//
//  UserRepositoryViewDataSource.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/07.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import UIKit
import GithubKit

final class UserRepositoryViewDataSource: NSObject {
    let fetchRepositories: () -> ()
    let repositories: () -> [Repository]
    let isFetchingRepositories: () -> Bool
    let selectedRepository: (Repository) -> Void
    
    fileprivate let loadingView = LoadingView.makeFromNib()
    
    fileprivate var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                fetchRepositories()
            }
        }
    }
    
    init(fetchRepositories: @escaping () -> (),
         repositories: @escaping () -> [Repository],
         isFetchingRepositories: @escaping () -> Bool,
         selectedRepository: @escaping (Repository) -> Void) {
        self.fetchRepositories = fetchRepositories
        self.repositories = repositories
        self.isFetchingRepositories = isFetchingRepositories
        self.selectedRepository = selectedRepository
        
        super.init()
    }
    
    func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.registerCell(RepositoryViewCell.self)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.className)
    }
}

extension UserRepositoryViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(RepositoryViewCell.self, for: indexPath)
        cell.configure(with: repositories()[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: UITableViewHeaderFooterView.className) else {
            return nil
        }
        loadingView.removeFromSuperview()
        loadingView.isLoading = isFetchingRepositories()
        loadingView.add(to: view)
        return view
    }
}

extension UserRepositoryViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let repository = repositories()[indexPath.row]
        selectedRepository(repository)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RepositoryViewCell.calculateHeight(with: repositories()[indexPath.row], and: tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return isFetchingRepositories() ? LoadingView.defaultHeight : .leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
        isReachedBottom = maxScrollDistance <= scrollView.contentOffset.y
    }
}
