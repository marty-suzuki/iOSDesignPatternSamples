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

<<<<<<< HEAD
final class FavoriteViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var favoritesInput: AnyObserver<[Repository]> { return favorites.asObserver() }
    var favoritesOutput: Observable<[Repository]> { return viewModel.favorites }

    private let _selectedIndexPath = PublishSubject<IndexPath>()

    private lazy var dataSource: FavoriteViewDataSource = {
        return .init(viewModel: self.viewModel,
                     selectedIndexPath: self._selectedIndexPath.asObserver())
    }()
    private private(set) lazy var viewModel: FavoriteViewModel = {
        .init(favoritesObservable: self.favorites,
              selectedIndexPath: self._selectedIndexPath)
    }()
    
    private let favorites = PublishSubject<[Repository]>()
    private let disposeBag = DisposeBag()
=======
protocol FavoriteView: class {
    func reloadData()
    func showRepository(with repository: Repository)
}

final class FavoriteViewController: UIViewController, FavoriteView {
    @IBOutlet private(set) weak var tableView: UITableView!
>>>>>>> mvp
    
    let presenter: FavoritePresenter
    let dataSource: FavoriteViewDataSource

    init(presenter: FavoritePresenter) {
        self.presenter = presenter
        self.dataSource = FavoriteViewDataSource(presenter: presenter)
        super.init(nibName: FavoriteViewController.className, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"
<<<<<<< HEAD
        automaticallyAdjustsScrollViewInsets = false
=======

        presenter.view = self
>>>>>>> mvp
        dataSource.configure(with: tableView)

        // observe viewModel
        viewModel.selectedRepository
            .bind(to: showRepository)
            .disposed(by: disposeBag)
        
        viewModel.relaodData
            .bind(to: reloadData)
            .disposed(by: disposeBag)
    }
    
<<<<<<< HEAD
    private var showRepository: AnyObserver<Repository> {
        return Binder(self) { me, repository in
            let vc = RepositoryViewController(repository: repository,
                                              favoritesOutput: me.favoritesOutput,
                                              favoritesInput: me.favoritesInput)
            me.navigationController?.pushViewController(vc, animated: true)
        }.asObserver()
=======
    func showRepository(with repository: Repository) {
        let repositoryPresenter = RepositoryViewPresenter(repository: repository, favoritePresenter: presenter)
        let vc = RepositoryViewController(presenter: repositoryPresenter)
        navigationController?.pushViewController(vc, animated: true)
>>>>>>> mvp
    }
    
    private var reloadData: AnyObserver<Void> {
        return Binder(self) { me, _ in
            me.tableView.reloadData()
        }.asObserver()
    }
}
