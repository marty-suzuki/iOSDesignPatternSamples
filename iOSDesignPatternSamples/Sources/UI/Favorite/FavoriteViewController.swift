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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"
        automaticallyAdjustsScrollViewInsets = false
        dataSource.configure(with: tableView)

        // observe viewModel
        viewModel.selectedRepository
            .bind(to: showRepository)
            .disposed(by: disposeBag)
        
        viewModel.relaodData
            .bind(to: reloadData)
            .disposed(by: disposeBag)
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
}
