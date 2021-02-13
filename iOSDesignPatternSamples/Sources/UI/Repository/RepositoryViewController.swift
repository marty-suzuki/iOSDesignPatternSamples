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
    private let flux: Flux

    private let _favoriteButtonTap = PassthroughSubject<Void, Never>()

    init?(flux: Flux) {
        guard let repository = flux.repositoryStore.selectedRepository else { return nil }
        self.flux = flux
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

        let store = flux.repositoryStore
        let action = flux.repositoryAction

        let repository = store.$selectedRepository
            .flatMap { repository -> AnyPublisher<Repository, Never> in
                guard let repository = repository else {
                    return Empty().eraseToAnyPublisher()
                }
                return Just(repository).eraseToAnyPublisher()
            }

        let containsRepository = repository
            .combineLatest(store.$favorites) { repo, favs in
                (favs.contains { $0.url == repo.url }, repo)
            }

        let buttonTapAndRepository = _favoriteButtonTap
            .flatMap { containsRepository }

        buttonTapAndRepository
            .filter { $0.0 }
            .receive(on: DispatchQueue.main)
            .sink {
                action.removeFavorite($1)
            }
            .store(in: &cancellables)

        buttonTapAndRepository
            .filter { !$0.0 }
            .receive(on: DispatchQueue.main)
            .sink {
                action.addFavorite($1)
            }
            .store(in: &cancellables)

        containsRepository
            .map { $0.0 ? "Remove" : "Add" }
            .receive(on: DispatchQueue.main)
            .assign(to: \.title, on: favoriteButtonItem)
            .store(in: &cancellables)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        flux.repositoryAction.clearSelectedRepository()
    }

    @objc private func favoriteButtonTap(_: UIBarButtonItem) {
        _favoriteButtonTap.send()
    }
}
