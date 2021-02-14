//
//  UserRepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit
import UIKit

final class UserRepositoryViewController: UIViewController {

    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var totalCountLabel: UILabel!

    let loadingView = LoadingView()

    let action: UserRepositoryActionType
    let store: UserRepositoryStoreType
    let dataSource: UserRepositoryViewDataSource

    private let makeRepositoryAction: (Repository) -> RepositoryActionType
    private let makeRepositoryStore: (Repository) -> RepositoryStoreType
    private var cacellables = Set<AnyCancellable>()

    init(
        action: UserRepositoryActionType,
        store: UserRepositoryStoreType,
        makeRepositoryAction: @escaping (Repository) -> RepositoryActionType,
        makeRepositoryStore: @escaping (Repository) -> RepositoryStoreType

    ) {
        self.action = action
        self.store = store
        self.makeRepositoryAction = makeRepositoryAction
        self.makeRepositoryStore = makeRepositoryStore
        self.dataSource = UserRepositoryViewDataSource(
            action: action,
            store: store
        )
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = store.title

        dataSource.configure(with: tableView)

        store.selectedRepository
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: showRepository)
            .store(in: &cacellables)

        store.reloadData
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reloadData)
            .store(in: &cacellables)

        store.countStringPublisher
            .map(Optional.some)
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: totalCountLabel)
            .store(in: &cacellables)

        store.updateLoadingView
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: updateLoadingView)
            .store(in: &cacellables)

        action.load()
        action.fetchRepositories()
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

    private var updateLoadingView: (UIView, Bool) -> Void {
        { [weak self] view, isLoading in
            self?.loadingView.removeFromSuperview()
            self?.loadingView.isLoading = isLoading
            self?.loadingView.add(to: view)
        }
    }
}
