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
    private let favoriteButtonItem: UIBarButtonItem
    private let disposeBag = DisposeBag()
    private let viewModel: RepositoryViewModel

<<<<<<< HEAD
    init(repository: Repository,
         favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>,
         entersReaderIfAvailable: Bool = true) {
        let favoriteButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        self.favoriteButtonItem = favoriteButtonItem
        self.viewModel = RepositoryViewModel(repository: repository,
                                             favoritesOutput: favoritesOutput,
                                             favoritesInput: favoritesInput,
                                             favoriteButtonTap: favoriteButtonItem.rx.tap)

        super.init(url: repository.url, entersReaderIfAvailable: entersReaderIfAvailable)
        hidesBottomBarWhenPushed = true
=======
final class RepositoryViewController: SFSafariViewController, RepositoryView {
    private(set) lazy var favoriteButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(title: self.presenter.favoriteButtonTitle,
                               style: .plain,
                               target: self,
                               action: #selector(RepositoryViewController.favoriteButtonTap(_:)))
    }()
    private let presenter: RepositoryPresenter
    
    init(presenter: RepositoryPresenter) {
        self.presenter = presenter
        super.init(url: presenter.url, configuration: .init())
        hidesBottomBarWhenPushed = true

>>>>>>> mvp
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = favoriteButtonItem

<<<<<<< HEAD
        viewModel.favoriteButtonTitle
            .bind(to: favoriteButtonItem.rx.title)
            .disposed(by: disposeBag)
=======
        presenter.view = self
    }
    
    @objc private func favoriteButtonTap(_ sender: UIBarButtonItem) {
        presenter.favoriteButtonTap()
    }
    
    func updateFavoriteButtonTitle(_ title: String) {
        favoriteButtonItem.title = title
>>>>>>> mvp
    }
}
