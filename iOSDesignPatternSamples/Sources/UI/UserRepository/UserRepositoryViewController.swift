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

<<<<<<< HEAD
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
=======
    let loadingView = LoadingView.makeFromNib()

    let viewModel: UserRepositoryViewModel
    let dataSource: UserRepositoryViewDataSource

    private let disposeBag = DisposeBag()

    init(user: User,
         favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>) {
        self.viewModel = UserRepositoryViewModel(user: user,
                                                 favoritesOutput: favoritesOutput,
                                                 favoritesInput: favoritesInput)
        self.dataSource = UserRepositoryViewDataSource(viewModel: viewModel)
>>>>>>> mvvm
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

<<<<<<< HEAD
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
=======
        title = viewModel.title

        dataSource.configure(with: tableView)

        viewModel.output.showRepository
            .bind(to: showRepository)
            .disposed(by: disposeBag)

        viewModel.output.reloadData
            .bind(to: reloadData)
            .disposed(by: disposeBag)

        viewModel.output.countString
            .bind(to: totalCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.updateLoadingView
            .bind(to: updateLoadingView)
>>>>>>> mvvm
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
        
<<<<<<< HEAD
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
=======
        viewModel.input.fetchRepositories.onNext(())
    }
    
    private var showRepository: Binder<Repository> {
        return Binder(self) { me, repository in
            let vc = RepositoryViewController(repository: repository,
                                              favoritesOutput: me.viewModel.output.favorites,
                                              favoritesInput: me.viewModel.input.favorites)
>>>>>>> mvvm
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
