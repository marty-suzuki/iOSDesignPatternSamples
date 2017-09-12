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

    private let dataSource = FavoriteViewDataSource()
    private let disposeBag = DisposeBag()
    private let store: RepositoryStore = .instantiate()
    private let action = RepositoryAction()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"
        automaticallyAdjustsScrollViewInsets = false
        dataSource.configure(with: tableView)

        // observe store
        rx.methodInvoked(#selector(FavoriteViewController.viewDidAppear(_:)))
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let me = self else { return .empty() }
                let viewWillDisappear = me.rx
                    .sentMessage(#selector(FavoriteViewController.viewDidDisappear(_:)))
                return me.store.selectedRepository
                    .takeUntil(viewWillDisappear)
                    .filter { $0 != nil }
                    .map { _ in }
            }
            .bind(to: showRepository)
            .disposed(by: disposeBag)

        Observable.merge(store.isRepositoryFetching.map { _ in },
                         store.favorites.map { _ in })
            .bind(to: reloadData)
            .disposed(by: disposeBag)
    }
    
    private var showRepository: AnyObserver<Void> {
        return UIBindingObserver(UIElement: self) { me, _ in
            guard let vc = RepositoryViewController() else { return }
            me.navigationController?.pushViewController(vc, animated: true)
        }.asObserver()
    }
    
    private var reloadData: AnyObserver<Void> {
        return UIBindingObserver(UIElement: self) { me, _ in
            me.tableView.reloadData()
        }.asObserver()
    }
}
