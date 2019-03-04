//
//  UserRepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit
import RxSwift
import RxCocoa

final class UserRepositoryViewController: UIViewController {

    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var totalCountLabel: UILabel!

    let loadingView = LoadingView.makeFromNib()

    let flux: Flux
    let dataSource: UserRepositoryViewDataSource

    private let disposeBag = DisposeBag()

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

        let repositories = repositoryStore.repositories.asObservable()
        let totalCount = repositoryStore.repositoryTotalCount.asObservable()
        let isFetching = repositoryStore.isRepositoryFetching.asObservable()

        repositoryStore.selectedRepository
            .filter { $0 != nil }
            .map { _ in }
            .bind(to: showRepository)
            .disposed(by: disposeBag)

        Observable.merge(repositories.map { _ in },
                         totalCount.map { _ in },
                         isFetching.map { _ in })
            .bind(to: reloadData)
            .disposed(by: disposeBag)

        Observable.combineLatest(dataSource.headerFooterView, isFetching)
            .bind(to: updateLoadingView)
            .disposed(by: disposeBag)

        Observable.combineLatest(repositories, totalCount)
            .map { (repos, count) in "\(repos.count) / \(count)" }
            .bind(to: totalCountLabel.rx.text)
            .disposed(by: disposeBag)

        let user = flux.userStore.selectedUser
            .flatMap { $0.map(Observable.just) ?? .empty() }

        user
            .map { "\($0.login)'s Repositories" }
            .bind(to: rx.title)
            .disposed(by: disposeBag)

        // fetch repositories
        let fetchRepositories = PublishSubject<Void>()
        let _fetchTrigger = PublishSubject<(User, String?)>()

        let initialLoadRequest = fetchRepositories
            .withLatestFrom(_fetchTrigger)

        let loadMoreRequest = dataSource.isReachedBottom
            .filter { $0 }
            .withLatestFrom(_fetchTrigger)
            .filter { $1 != nil }
        
        Observable.merge(initialLoadRequest, loadMoreRequest)
            .map { UserNodeRequest(id: $0.id, after: $1) }
            .distinctUntilChanged { $0.id == $1.id && $0.after == $1.after }
            .subscribe(onNext: { request in
                repositoryAction.fetchRepositories(withUserID: request.id,
                                                   after: request.after)
            })
            .disposed(by: disposeBag)

        let endCousor = repositoryStore.lastPageInfo.asObservable()
            .map { $0?.endCursor }

        Observable.combineLatest(user, endCousor)
            .bind(to: _fetchTrigger)
            .disposed(by: disposeBag)

        fetchRepositories.onNext(())
    }
    
    private var showRepository: Binder<Void> {
        return Binder(self) { me, repository in
            guard let vc = RepositoryViewController(flux: me.flux) else { return }
            me.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private var reloadData: Binder<Void> {
        return Binder(tableView) { tableView, _ in
            tableView.reloadData()
        }
    }
    
    private var updateLoadingView: Binder<(UIView, Bool)> {
        return Binder(loadingView) { (loadingView, value: (view: UIView, isLoading: Bool)) in
            loadingView.removeFromSuperview()
            loadingView.isLoading = value.isLoading
            loadingView.add(to: value.view)
        }
    }
}
