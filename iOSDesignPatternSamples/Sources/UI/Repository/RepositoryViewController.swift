//
//  RepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit
import SafariServices
import UIKit

final class RepositoryViewController: SFSafariViewController {
    private var cancellables = Set<AnyCancellable>()
    private let viewModel: RepositoryViewModel

    init(repository: Repository,
         favoritesOutput: AnyPublisher<[Repository], Never>,
         favoritesInput: @escaping ([Repository]) -> Void) {
        self.viewModel = RepositoryViewModel(repository: repository,
                                             favoritesOutput: favoritesOutput,
                                             favoritesInput: favoritesInput)

        super.init(url: repository.url, configuration: .init())
        hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let favoriteButtonItem = UIBarButtonItem(
            title: nil,
            style: .plain,
            target: self,
            action: #selector(self.favoriteButtonTap(_:))
        )
        navigationItem.rightBarButtonItem = favoriteButtonItem

        viewModel.output.favoriteButtonTitle
            .map(Optional.some)
            .receive(on: DispatchQueue.main)
            .assign(to: \.title, on: favoriteButtonItem)
            .store(in: &cancellables)
    }

    @objc private func favoriteButtonTap(_: UIBarButtonItem) {
        viewModel.input.favoriteButtonTap()
    }
}
