//
//  RepositoryViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import SafariServices
import GithubKit
import RxSwift
import RxCocoa

final class RepositoryViewController: SFSafariViewController {
    private let favoriteButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
    private let disposeBag = DisposeBag()
    private let action: RepositoryAction
    private let store: RepositoryStore

    init?(action: RepositoryAction = .init(),
         store: RepositoryStore = .instantiate(),
         entersReaderIfAvailable: Bool = true) {
        guard let repository = store.value.selectedRepository else { return nil }
        self.action = action
        self.store = store
        super.init(url: repository.url, entersReaderIfAvailable: entersReaderIfAvailable)
        hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = favoriteButtonItem

        // observe store
        let repository = store.selectedRepository
            .flatMap { $0.map(Observable.just) ?? .empty() }

        let containsRepository = Observable.combineLatest(repository, store.favorites)
            { repo, favs in (favs.contains { $0.url == repo.url }, repo) }

        let buttonTapAndRepository = favoriteButtonItem.rx.tap
            .withLatestFrom(containsRepository)
            .share()

        buttonTapAndRepository
            .filter { $0.0 }
            .subscribe(onNext: { [weak self] in
                self?.action.removeFavorite($1)
            })
            .disposed(by: disposeBag)

        buttonTapAndRepository
            .filter { !$0.0 }
            .subscribe(onNext: { [weak self] in
                self?.action.addFavorite($1)
            })
            .disposed(by: disposeBag)

        containsRepository
            .map { $0.0 ? "Remove" : "Add" }
            .bind(to: favoriteButtonItem.rx.title)
            .disposed(by: disposeBag)

        rx.sentMessage(#selector(RepositoryViewController.viewDidDisappear(_:)))
            .subscribe(onNext: { [weak self] _ in
                self?.action.clearSelectedRepository()
            })
            .disposed(by: disposeBag)
    }
}
