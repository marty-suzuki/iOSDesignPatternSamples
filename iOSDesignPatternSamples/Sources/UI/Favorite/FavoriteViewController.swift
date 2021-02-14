//
//  FavoriteViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit
import UIKit

final class FavoriteViewController: UIViewController {
    @IBOutlet private(set) weak var tableView: UITableView!

    let action: FavoriteActionType
    let store: FavoriteStoreType
    let dataSource: FavoriteViewDataSource
    private let makeRepositoryAction: (Repository) -> RepositoryActionType
    private let makeRepositoryStore: (Repository) -> RepositoryStoreType
    private var cancellables = Set<AnyCancellable>()

    init(
        action: FavoriteActionType,
        store: FavoriteStoreType,
        makeRepositoryAction: @escaping (Repository) -> RepositoryActionType,
        makeRepositoryStore: @escaping (Repository) -> RepositoryStoreType
    ) {
        self.action = action
        self.store = store
        self.dataSource = FavoriteViewDataSource(
            action: action,
            store: store
        )
        self.makeRepositoryAction = makeRepositoryAction
        self.makeRepositoryStore = makeRepositoryStore
        super.init(nibName: FavoriteViewController.className, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On Memory Favorite"
        dataSource.configure(with: tableView)

        store.selectedRepository
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: showRepository)
            .store(in: &cancellables)

        store.reloadData
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reloadData)
            .store(in: &cancellables)

        action.load()
    }

    private var showRepository: (Repository) -> Void {
        { [weak self] repository in
            guard let me = self else {
                return
            }

            let vc = RepositoryViewController(
                action: me.makeRepositoryAction(repository),
                store: me.makeRepositoryStore(repository)
            )
            me.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private var reloadData: () -> Void {
        { [weak self] in
            self?.tableView.reloadData()
        }
    }
}
