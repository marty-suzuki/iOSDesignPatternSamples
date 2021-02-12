//
//  SearchViewDataSource.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit
import UIKit

final class SearchViewDataSource: NSObject {

    private let viewModel: SearchViewModel

    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
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
        return viewModel.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UserViewCell.self, for: indexPath)
        let user = viewModel.users[indexPath.row]
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
        viewModel.input.headerFooterView(view)
        return view
    }
}

extension SearchViewDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        viewModel.input.selectedIndexPath(indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let user = viewModel.users[indexPath.row]
        return UserViewCell.calculateHeight(with: user, and: tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return viewModel.isFetchingUsers ? LoadingView.defaultHeight : .leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
        viewModel.input.isReachedBottom(maxScrollDistance <= scrollView.contentOffset.y)
    }
}
