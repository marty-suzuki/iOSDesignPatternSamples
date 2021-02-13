//
//  UserRepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit
import UIKit

final class UserRepositoryViewController: UIViewController {

    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var totalCountLabel: UILabel!

    let loadingView = LoadingView()

    let flux: Flux
    let dataSource: UserRepositoryViewDataSource

    private var cacellables = Set<AnyCancellable>()

    init(flux: Flux) {
        self.flux = flux
        self.dataSource = UserRepositoryViewDataSource(flux: flux)
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        flux.userAction.clearSelectedUser()
        flux.repositoryAction.removeAllRepositories()
        flux.repositoryAction.repositoryTotalCount(0)
        flux.repositoryAction.clearPageInfo()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.configure(with: tableView)

        let repositoryAction = flux.repositoryAction
        let repositoryStore = flux.repositoryStore

        let repositories = repositoryStore.$repositories
        let totalCount = repositoryStore.$repositoryTotalCount
        let isFetching = repositoryStore.$isRepositoryFetching

        repositoryStore.$selectedRepository
            .filter { $0 != nil }
            .map { _ in }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: showRepository)
            .store(in: &cacellables)

        repositories.map { _ in }
            .merge(with: totalCount.map { _ in }, isFetching.map { _ in })
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reloadData)
            .store(in: &cacellables)

        dataSource.headerFooterView
            .combineLatest(isFetching)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: updateLoadingView)
            .store(in: &cacellables)

        repositories
            .combineLatest(totalCount) { repos, count in
                "\(repos.count) / \(count)"
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: totalCountLabel)
            .store(in: &cacellables)

        let user = flux.userStore.$selectedUser
            .flatMap { user -> AnyPublisher<User, Never> in
                guard let user = user else {
                    return Empty().eraseToAnyPublisher()
                }
                return Just(user).eraseToAnyPublisher()
            }

        user
            .map { "\($0.login)'s Repositories" }
            .assign(to: \.title, on: self)
            .store(in: &cacellables)

        // fetch repositories
        let fetchRepositories = PassthroughSubject<Void, Never>()
        var _fetchTrigger: (User, String?)?

        let initialLoadRequest = fetchRepositories
            .flatMap { _ -> AnyPublisher<(User, String?), Never> in
                guard let param = _fetchTrigger else {
                    return Empty().eraseToAnyPublisher()
                }
                return Just(param).eraseToAnyPublisher()
            }

        let loadMoreRequest = dataSource.isReachedBottom
            .filter { $0 }
            .flatMap { _ -> AnyPublisher<(User, String?), Never> in
                guard let param = _fetchTrigger else {
                    return Empty().eraseToAnyPublisher()
                }
                return Just(param).eraseToAnyPublisher()
            }
            .filter { $1 != nil }
        
        initialLoadRequest
            .merge(with: loadMoreRequest)
            .map { UserNodeRequest(id: $0.id, after: $1) }
            .removeDuplicates { $0.id == $1.id && $0.after == $1.after }
            .sink { request in
//                repositoryAction.fetchRepositories(withUserID: request.id,
//                                                   after: request.after)
            }
            .store(in: &cacellables)

        let endCousor = repositoryStore.$lastPageInfo
            .map { $0?.endCursor }

        user
            .combineLatest(endCousor)
            .sink {
                _fetchTrigger = $0
            }
            .store(in: &cacellables)

        fetchRepositories.send()
    }

    private var showRepository: () -> Void {
        { [weak self] in
            guard
                let me = self,
                let vc = RepositoryViewController(flux: me.flux)
            else {
                return
            }
            me.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private var reloadData: () -> Void {
        { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private var updateLoadingView: (UIView, Bool) -> Void {
        { [weak self] view, isLoading in
            self?.loadingView.removeFromSuperview()
            self?.loadingView.isLoading = isLoading
            self?.loadingView.add(to: view)
        }
    }
}
