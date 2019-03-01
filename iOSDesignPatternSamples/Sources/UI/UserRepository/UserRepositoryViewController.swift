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

<<<<<<< HEAD
final class UserRepositoryViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalCountLabel: UILabel!

    private let loadingView = LoadingView.makeFromNib()

    private let _selectedIndexPath = PublishSubject<IndexPath>()
    private let _isReachedBottom = PublishSubject<Bool>()
    private let _headerFooterView = PublishSubject<UIView>()
    private let _fetchRepositories = PublishSubject<Void>()

    private lazy var dataSource: UserRepositoryViewDataSource = {
        return .init(viewModel: self.viewModel,
                     selectedIndexPath: self._selectedIndexPath.asObserver(),
                     isReachedBottom: self._isReachedBottom.asObserver(),
                     headerFooterView: self._headerFooterView.asObserver())
    }()
    private lazy var viewModel: UserRepositoryViewModel = {
        return .init(user: self.user,
                     fetchRepositories: self._fetchRepositories,
                     selectedIndexPath: self._selectedIndexPath,
                     isReachedBottom: self._isReachedBottom,
                     headerFooterView: self._headerFooterView)
    }()

    private let favoritesOutput: Observable<[Repository]>
    private let favoritesInput: AnyObserver<[Repository]>

    private let disposeBag = DisposeBag()
    
    private let user: User
    
    init(user: User,
         favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>) {
        self.favoritesOutput = favoritesOutput
        self.favoritesInput = favoritesInput
        self.user = user
=======
protocol UserRepositoryView: class {
    func reloadData()
    func showRepository(with repository: Repository)
    func updateTotalCountLabel(_ countText: String)
    func updateLoadingView(with view: UIView, isLoading: Bool)
}

final class UserRepositoryViewController: UIViewController, UserRepositoryView {

    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var totalCountLabel: UILabel!

    let loadingView = LoadingView.makeFromNib()

    let favoritePresenter: FavoritePresenter
    let userRepositoryPresenter: UserRepositoryPresenter
    let dataSource: UserRepositoryViewDataSource
    
    init(userRepositoryPresenter: UserRepositoryPresenter, favoritePresenter: FavoritePresenter) {
        self.favoritePresenter = favoritePresenter
        self.userRepositoryPresenter = userRepositoryPresenter
        self.dataSource = UserRepositoryViewDataSource(presenter: userRepositoryPresenter)
        
>>>>>>> mvp
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
<<<<<<< HEAD

        edgesForExtendedLayout = []
        dataSource.configure(with: tableView)
        title = viewModel.title

        // observe viewModel
        viewModel.showRepository
            .bind(to: showRepository)
            .disposed(by: disposeBag)

        viewModel.reloadData
            .bind(to: reloadData)
            .disposed(by: disposeBag)

        viewModel.countString
            .bind(to: totalCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.updateLoadingView
            .bind(to: updateLoadingView)
            .disposed(by: disposeBag)
        
        _fetchRepositories.onNext(())
=======
        
        title = userRepositoryPresenter.title
        
        dataSource.configure(with: tableView)

        userRepositoryPresenter.view = self
        userRepositoryPresenter.fetchRepositories()
    }
    
    func showRepository(with repository: Repository) {
        let repositoryPresenter = RepositoryViewPresenter(repository: repository, favoritePresenter: favoritePresenter)
        let vc = RepositoryViewController(presenter: repositoryPresenter)
        navigationController?.pushViewController(vc, animated: true)
>>>>>>> mvp
    }
    
    private var showRepository: AnyObserver<Repository> {
        return Binder(self) { me, repository in
            let vc = RepositoryViewController(repository: repository,
                                              favoritesOutput: me.favoritesOutput,
                                              favoritesInput: me.favoritesInput)
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
