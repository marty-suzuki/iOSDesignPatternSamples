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

    let viewModel: FavoriteViewModelType
    let dataSource: FavoriteViewDataSource

    private let makeRepositoryViewModel: (Repository) -> RepositoryViewModelType
    private var cancellables = Set<AnyCancellable>()

    init(
        viewModel: FavoriteViewModelType,
        makeRepositoryViewModel: @escaping (Repository) -> RepositoryViewModelType
    ) {
        self.makeRepositoryViewModel = makeRepositoryViewModel
        self.viewModel = viewModel
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

        viewModel.output.selectedRepository
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: showRepository)
            .store(in: &cancellables)

        viewModel.output.relaodData
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reloadData)
            .store(in: &cancellables)
    }

    private var showRepository: (Repository) -> Void {
        { [weak self] repository in
            guard let me = self else {
                return
            }
            let vm = me.makeRepositoryViewModel(repository)
            let vc = RepositoryViewController(viewModel: vm)
            me.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private var reloadData: () -> Void {
        { [weak self] in
            self?.tableView.reloadData()
        }
    }
}
