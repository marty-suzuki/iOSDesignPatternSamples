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
    
    private lazy var dataSource: UserRepositoryViewDataSource = .init(viewModel: self.viewModel)
    private lazy var viewModel: UserRepositoryViewModel = {
        return .init(user: self.user,
                     fetchRepositories: self.fetchRepositories,
                     selectedIndexPath: self.selectedIndexPath,
                     isReachedBottom: self.isReachedBottom,
                     headerFooterView: self.headerFooterView)
    }()

    private let favoritesOutput: Observable<[Repository]>
    private let favoritesInput: AnyObserver<[Repository]>

    private let selectedIndexPath = PublishSubject<IndexPath>()
    private let isReachedBottom = PublishSubject<Bool>()
    private let headerFooterView = PublishSubject<UIView>()
    private let fetchRepositories = PublishSubject<Void>()
    private let disposeBag = DisposeBag()
    
    private let user: User
    
    init(user: User,
         favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>) {
        self.favoritesOutput = favoritesOutput
        self.favoritesInput = favoritesInput
        self.user = user
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = []
        dataSource.configure(with: tableView)

        // observe dataSource
        dataSource.selectedIndexPath
            .bind(to: selectedIndexPath)
            .disposed(by: disposeBag)
        dataSource.isReachedBottom
            .bind(to: isReachedBottom)
            .disposed(by: disposeBag)
        dataSource.headerFooterView
            .bind(to: headerFooterView)
            .disposed(by: disposeBag)

        // observe viewModel
        viewModel.title
            .bind(to: rx.title)
            .disposed(by: disposeBag)
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
        
        fetchRepositories.onNext(())
    }
    
    private var showRepository: AnyObserver<Repository> {
        return UIBindingObserver(UIElement: self) { me, repository in
            let vc = RepositoryViewController(repository: repository,
                                              favoritesOutput: me.favoritesOutput,
                                              favoritesInput: me.favoritesInput)
            me.navigationController?.pushViewController(vc, animated: true)
        }.asObserver()
    }
    
    private var reloadData: AnyObserver<Void> {
        return UIBindingObserver(UIElement: self) { me, _ in
            me.tableView.reloadData()
        }.asObserver()
    }
    
    private var updateLoadingView: AnyObserver<(UIView, Bool)> {
        return UIBindingObserver(UIElement: self) { (me, value: (view: UIView, isLoading: Bool)) in
            me.loadingView.removeFromSuperview()
            me.loadingView.isLoading = value.isLoading
            me.loadingView.add(to: value.view)
        }.asObserver()
    }
}
