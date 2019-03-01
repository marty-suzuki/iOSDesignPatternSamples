//
//  UserRepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

<<<<<<< HEAD
protocol UserRepositoryView: class {
    func reloadData()
    func showRepository(with repository: Repository)
    func updateTotalCountLabel(_ countText: String)
    func updateLoadingView(with view: UIView, isLoading: Bool)
}

final class UserRepositoryViewController: UIViewController, UserRepositoryView {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalCountLabel: UILabel!

    private let loadingView = LoadingView.makeFromNib()
    private let favoritePresenter: FavoritePresenter
    private let presenter: UserRepositoryPresenter

    private lazy var dataSource: UserRepositoryViewDataSource = .init(presenter: self.presenter)

    init(user: User, favoritePresenter: FavoritePresenter) {
        self.favoritePresenter = favoritePresenter
        self.presenter = UserRepositoryViewPresenter(user: user)
=======
final class UserRepositoryViewController: UIViewController {
    
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var totalCountLabel: UILabel!

    let loadingView = LoadingView.makeFromNib()
    
    private var isReachedBottom: Bool = false {
        didSet {
            if isReachedBottom && isReachedBottom != oldValue {
                repositoryModel.fetchRepositories()
            }
        }
    }

    let favoriteModel: FavoriteModel
    let repositoryModel: RepositoryModel
    
    init(repositoryModel: RepositoryModel, favoriteModel: FavoriteModel) {
        self.repositoryModel = repositoryModel
        self.favoriteModel = favoriteModel
        
>>>>>>> mvc
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
        presenter.view = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
<<<<<<< HEAD

        title = presenter.title

        dataSource.configure(with: tableView)
        presenter.fetchRepositories()
    }

    func showRepository(with repository: Repository) {
        let vc = RepositoryViewController(repository: repository, favoritePresenter: favoritePresenter)
=======
        
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
        let vc = RepositoryViewController(repository: repository, favoriteModel: favoriteModel)
>>>>>>> mvc
        navigationController?.pushViewController(vc, animated: true)
    }

<<<<<<< HEAD
    func reloadData() {
        tableView.reloadData()
=======
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
>>>>>>> mvc
    }

    func updateTotalCountLabel(_ countText: String) {
        totalCountLabel.text = countText
    }

    func updateLoadingView(with view: UIView, isLoading: Bool) {
        loadingView.removeFromSuperview()
<<<<<<< HEAD
        loadingView.isLoading = isLoading
        loadingView.add(to: view)
=======
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
>>>>>>> mvc
    }
}
