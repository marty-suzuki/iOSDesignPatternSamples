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
    private let disposeBag = DisposeBag()
    private let viewModel: RepositoryViewModel

    init(repository: Repository,
         favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>) {
        self.viewModel = RepositoryViewModel(repository: repository,
                                             favoritesOutput: favoritesOutput,
                                             favoritesInput: favoritesInput)

        super.init(url: repository.url, configuration: .init())
        hidesBottomBarWhenPushed = true

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let favoriteButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = favoriteButtonItem

        favoriteButtonItem.rx.tap
            .bind(to: viewModel.input.favoriteButtonTap)
            .disposed(by: disposeBag)

        viewModel.output.favoriteButtonTitle
            .bind(to: favoriteButtonItem.rx.title)
            .disposed(by: disposeBag)
    }
}
