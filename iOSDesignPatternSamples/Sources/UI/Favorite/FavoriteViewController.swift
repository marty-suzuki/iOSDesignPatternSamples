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

    private let dataSource: FavoriteViewDataSource
    private let viewModel: FavoriteViewModel
    
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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"

        dataSource.configure(with: tableView)

        // observe viewModel
        viewModel.output.selectedRepository
            .bind(to: showRepository)
            .disposed(by: disposeBag)
        
        viewModel.output.relaodData
            .bind(to: reloadData)
            .disposed(by: disposeBag)
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
}
