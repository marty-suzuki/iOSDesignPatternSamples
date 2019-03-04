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
    private let flux: Flux

    init?(flux: Flux) {
        guard let repository = flux.repositoryStore.value.selectedRepository else { return nil }
        self.flux = flux
        super.init(url: repository.url, configuration: .init())
        hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = favoriteButtonItem

        let store = flux.repositoryStore
        let action = flux.repositoryAction

        let repository = store.selectedRepository
            .flatMap { $0.map(Observable.just) ?? .empty() }

        let containsRepository = Observable.combineLatest(repository, store.favorites)
            { repo, favs in (favs.contains { $0.url == repo.url }, repo) }

        let buttonTapAndRepository = favoriteButtonItem.rx.tap
            .withLatestFrom(containsRepository)
            .share()

        buttonTapAndRepository
            .filter { $0.0 }
            .subscribe(onNext: {
                action.removeFavorite($1)
            })
            .disposed(by: disposeBag)

        buttonTapAndRepository
            .filter { !$0.0 }
            .subscribe(onNext: {
                action.addFavorite($1)
            })
            .disposed(by: disposeBag)

        containsRepository
            .map { $0.0 ? "Remove" : "Add" }
            .bind(to: favoriteButtonItem.rx.title)
            .disposed(by: disposeBag)

        rx.sentMessage(#selector(RepositoryViewController.viewDidDisappear(_:)))
            .subscribe(onNext: { _ in
                action.clearSelectedRepository()
            })
            .disposed(by: disposeBag)
    }
}
