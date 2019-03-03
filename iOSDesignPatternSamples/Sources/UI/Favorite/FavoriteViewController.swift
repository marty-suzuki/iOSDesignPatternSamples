//
//  FavoriteViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit
import RxSwift
import RxCocoa

final class FavoriteViewController: UIViewController {
    @IBOutlet private(set) weak var tableView: UITableView!

<<<<<<< HEAD
    private let dataSource = FavoriteViewDataSource()
    private let disposeBag = DisposeBag()
    private let store: RepositoryStore = .instantiate()
    private let action = RepositoryAction()
=======
    let viewModel: FavoriteViewModel
    let dataSource: FavoriteViewDataSource
    
    private let disposeBag = DisposeBag()

    init(favoritesInput: AnyObserver<[Repository]>,
         favoritesOutput: Observable<[Repository]>) {
        self.viewModel = FavoriteViewModel(favoritesInput: favoritesInput,
                                           favoritesOutput: favoritesOutput)
        self.dataSource = FavoriteViewDataSource(viewModel: viewModel)
        super.init(nibName: FavoriteViewController.className, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
>>>>>>> mvvm

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"

        dataSource.configure(with: tableView)

<<<<<<< HEAD
        // observe store
        let viewWillDisappear = rx
            .sentMessage(#selector(FavoriteViewController.viewDidDisappear(_:)))

        rx.methodInvoked(#selector(FavoriteViewController.viewDidAppear(_:)))
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                self.map { $0.store.selectedRepository
                    .takeUntil(viewWillDisappear)
                    .filter { $0 != nil }
                    .map { _ in }
                } ?? .empty()
            }
            .bind(to: showRepository)
            .disposed(by: disposeBag)

        store.favorites
            .map { _ in }
=======
        viewModel.output.selectedRepository
            .bind(to: showRepository)
            .disposed(by: disposeBag)
        
        viewModel.output.relaodData
>>>>>>> mvvm
            .bind(to: reloadData)
            .disposed(by: disposeBag)
    }
    
<<<<<<< HEAD
    private var showRepository: AnyObserver<Void> {
        return Binder(self) { me, _ in
            guard let vc = RepositoryViewController() else { return }
=======
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
}
