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
    private let action: RepositoryActionType
    private let store: RepositoryStoreType

    private let _favoriteButtonTap = PassthroughSubject<Void, Never>()

    init(
        action: RepositoryActionType,
        store: RepositoryStoreType
    ) {
        self.action = action
        self.store = store
        super.init(url: store.repository.url, configuration: .init())
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

        store.favoriteButtonTitlePublisher
            .map(Optional.some)
            .receive(on: DispatchQueue.main)
            .assign(to: \.title, on: favoriteButtonItem)
            .store(in: &cancellables)

        action.load()
    }

    @objc private func favoriteButtonTap(_: UIBarButtonItem) {
        action.toggleFavorite()
    }
}
