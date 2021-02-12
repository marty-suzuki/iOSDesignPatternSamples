//
//  UserRepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

final class UserRepositoryViewController: UIViewController {
    
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var totalCountLabel: UILabel!

    let loadingView = LoadingView()
    
    private var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                repositoryModel.fetchRepositories()
            }
        }
    }

    let repositoryModel: RepositoryModelType
    private let makeFavoriteModel: () -> FavoriteModelType
    
    init(
        repositoryModel: RepositoryModelType,
        makeFavoriteModel: @escaping () -> FavoriteModelType
    ) {
        self.repositoryModel = repositoryModel
        self.makeFavoriteModel = makeFavoriteModel
        
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "\(repositoryModel.user.login)'s Repositories"
        
        configure(with: tableView)

        repositoryModel.delegate = self
        repositoryModel.fetchRepositories()
    }
    
    private func configure(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(RepositoryViewCell.self)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.className)
    }
    
    private func showRepository(with repository: Repository) {
        let favoriteModel = makeFavoriteModel()
        let vc = RepositoryViewController(repository: repository, favoriteModel: favoriteModel)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension UserRepositoryViewController: RepositoryModelDelegate {
    func repositoryModel(_ repositoryModel: RepositoryModel, didChange isFetchingRepositories: Bool) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func repositoryModel(_ repositoryModel: RepositoryModel, didChange repositories: [Repository]) {
        let totalCount = repositoryModel.totalCount
        DispatchQueue.main.async {
            self.totalCountLabel.text = "\(repositories.count) / \(totalCount)"
            self.tableView.reloadData()
        }
    }

    func repositoryModel(_ repositoryModel: RepositoryModel, didChange totalCount: Int) {
        let repositories = repositoryModel.repositories
        DispatchQueue.main.async {
            self.totalCountLabel.text = "\(repositories.count) / \(totalCount)"
        }
    }
}

extension UserRepositoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositoryModel.repositories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(RepositoryViewCell.self, for: indexPath)
        cell.configure(with: repositoryModel.repositories[indexPath.row])
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
        loadingView.isLoading = repositoryModel.isFetchingRepositories
        loadingView.add(to: view)
        return view
    }
}

extension UserRepositoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let repository = repositoryModel.repositories[indexPath.row]
        showRepository(with: repository)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RepositoryViewCell.calculateHeight(with: repositoryModel.repositories[indexPath.row], and: tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return repositoryModel.isFetchingRepositories ? LoadingView.defaultHeight : .leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxScrollDistance = max(0, scrollView.contentSize.height - scrollView.bounds.size.height)
        isReachedBottom = maxScrollDistance <= scrollView.contentOffset.y
    }
}
