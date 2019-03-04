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
    private let flux: Flux
    private let disposeBag = DisposeBag()

    init(flux: Flux) {
        self.flux = flux
        self.dataSource = FavoriteViewDataSource(flux: flux)
        super.init(nibName: FavoriteViewController.className, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"
        dataSource.configure(with: tableView)

        let store = flux.repositoryStore

        Observable.merge(
            rx.methodInvoked(#selector(FavoriteViewController.viewDidAppear(_:)))
                .map { _ in true },
            rx.sentMessage(#selector(FavoriteViewController.viewDidDisappear(_:)))
                .map { _ in false }
            )
            .flatMapLatest { isAppearing -> Observable<Repository?> in
                isAppearing ? store.selectedRepository : .empty()
            }
            .filter { $0 != nil }
            .map { _ in }
            .bind(to: showRepository)
            .disposed(by: disposeBag)

        store.favorites
            .map { _ in }
            .bind(to: reloadData)
            .disposed(by: disposeBag)
    }
    
    private var showRepository: AnyObserver<Void> {
        return Binder(self) { me, _ in
            guard let vc = RepositoryViewController(flux: me.flux) else { return }
            me.navigationController?.pushViewController(vc, animated: true)
        }.asObserver()
    }
    
    private var reloadData: AnyObserver<Void> {
        return Binder(self) { me, _ in
            me.tableView.reloadData()
        }.asObserver()
    }
}
