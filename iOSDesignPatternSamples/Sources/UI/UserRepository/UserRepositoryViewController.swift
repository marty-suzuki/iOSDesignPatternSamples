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

    let viewModel: UserRepositoryViewModelType
    let dataSource: UserRepositoryViewDataSource

    private let makeRepositoryViewModel: (Repository) -> RepositoryViewModelType
    private var cacellables = Set<AnyCancellable>()

    init(
        viewModel: UserRepositoryViewModelType,
        makeRepositoryViewModel: @escaping (Repository) -> RepositoryViewModelType
    ) {
        self.makeRepositoryViewModel = makeRepositoryViewModel
        self.viewModel = viewModel
        self.dataSource = UserRepositoryViewDataSource(viewModel: viewModel)
        super.init(nibName: UserRepositoryViewController.className, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.output.title

        dataSource.configure(with: tableView)

        viewModel.output.showRepository
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: showRepository)
            .store(in: &cacellables)

        viewModel.output.reloadData
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reloadData)
            .store(in: &cacellables)

        viewModel.output.countString
            .map(Optional.some)
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: totalCountLabel)
            .store(in: &cacellables)

        viewModel.output.updateLoadingView
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: updateLoadingView)
            .store(in: &cacellables)

        viewModel.input.fetchRepositories()
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

    private var updateLoadingView: (UIView, Bool) -> Void {
        { [weak self] view, isLoading in
            self?.loadingView.removeFromSuperview()
            self?.loadingView.isLoading = isLoading
            self?.loadingView.add(to: view)
        }
    }
}
