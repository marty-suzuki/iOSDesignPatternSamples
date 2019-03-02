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

    private let dataSource: UserRepositoryViewDataSource
    private let viewModel: UserRepositoryViewModel

    private let disposeBag = DisposeBag()

    init(user: User,
         favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>) {
        self.viewModel = UserRepositoryViewModel(user: user,
                                                 favoritesOutput: favoritesOutput,
                                                 favoritesInput: favoritesInput)
        self.dataSource = UserRepositoryViewDataSource(viewModel: viewModel)
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.configure(with: tableView)
        title = viewModel.title

        // observe viewModel
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
            .disposed(by: disposeBag)
        
        viewModel.input.fetchRepositories.onNext(())
    }
    
    private var showRepository: Binder<Repository> {
        return Binder(self) { me, repository in
            let vc = RepositoryViewController(repository: repository,
                                              favoritesOutput: me.viewModel.output.favorites,
                                              favoritesInput: me.viewModel.input.favorites)
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
