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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalCountLabel: UILabel!

    private let loadingView = LoadingView.makeFromNib()

    private let dataSource = UserRepositoryViewDataSource()
    private let userAction: UserAction
    private let userStore: UserStore
    private let repositoryAction: RepositoryAction
    private let repositoryStore: RepositoryStore
    private let disposeBag = DisposeBag()

    init(userAction: UserAction = .init(),
         userStore: UserStore = .instantiate(),
         repositoryAction: RepositoryAction = .init(),
         repositoryStore: RepositoryStore = .instantiate()) {
        self.userAction = userAction
        self.userStore = userStore
        self.repositoryAction = repositoryAction
        self.repositoryStore = repositoryStore
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        userAction.clearSelectedUser()
        repositoryAction.removeAllRepositories()
        repositoryAction.repositoryTotalCount(0)
        repositoryAction.clearPageInfo()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = []
        dataSource.configure(with: tableView)

        // observe store
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

        let user = userStore.selectedUser
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
            .subscribe(onNext: { [weak self] request in
                self?.repositoryAction.fetchRepositories(withUserId: request.id,
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
    
    private var showRepository: AnyObserver<Void> {
        return Binder(self) { me, repository in
            guard let vc = RepositoryViewController() else { return }
            me.navigationController?.pushViewController(vc, animated: true)
        }.asObserver()
    }
    
    private var reloadData: AnyObserver<Void> {
        return Binder(self) { me, _ in
            me.tableView.reloadData()
        }.asObserver()
    }
    
    private var updateLoadingView: AnyObserver<(UIView, Bool)> {
        return Binder(self) { (me, value: (view: UIView, isLoading: Bool)) in
            me.loadingView.removeFromSuperview()
            me.loadingView.isLoading = value.isLoading
            me.loadingView.add(to: value.view)
        }.asObserver()
    }
}
