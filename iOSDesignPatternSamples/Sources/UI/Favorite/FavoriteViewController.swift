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

    let flux: Flux
    let dataSource: FavoriteViewDataSource

    private var cancellables = Set<AnyCancellable>()

    private let _viewDidAppear = PassthroughSubject<Void, Never>()
    private let _viewDidDisappear = PassthroughSubject<Void, Never>()

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

        _viewDidAppear
            .map { true }
            .merge(with: _viewDidDisappear.map { false })
            .map { isAppearing -> AnyPublisher<Repository?, Never> in
                guard isAppearing else {
                    return Empty().eraseToAnyPublisher()
                }
                return store.$selectedRepository.eraseToAnyPublisher()
            }
            .switchToLatest()
            .filter { $0 != nil }
            .map { _ in }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: showRepository)
            .store(in: &cancellables)

        store.$favorites
            .map { _ in }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reloadData)
            .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _viewDidAppear.send()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _viewDidDisappear.send()
    }

    private var showRepository: () -> Void {
        { [weak self] in
            guard
                let me = self,
                let vc = RepositoryViewController(flux: me.flux)
            else {
                return
            }
            me.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private var reloadData: () -> Void {
        { [weak self] in
            self?.tableView.reloadData()
        }
    }
}
