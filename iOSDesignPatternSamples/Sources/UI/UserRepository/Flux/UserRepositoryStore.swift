//
//  UserRepositoryStore.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import Foundation
import GithubKit
import UIKit

protocol UserRepositoryStoreType: AnyObject {
    var repositories: [Repository] { get }
    var isRepositoryFetching: Bool { get }
    var title: String { get }
    var countStringPublisher: Published<String>.Publisher { get }
    var selectedRepository: AnyPublisher<Repository, Never> { get }
    var reloadData: AnyPublisher<Void, Never> { get }
    var updateLoadingView: AnyPublisher<(UIView, Bool), Never> { get }
}

final class UserRepositoryStore: UserRepositoryStoreType {
    @Published
    private(set) var repositories: [Repository] = []
    @Published
    private(set) var isRepositoryFetching = false
    @Published
    private(set) var title: String
    @Published
    private(set) var countString: String = ""

    var countStringPublisher: Published<String>.Publisher {
        $countString
    }

    let selectedRepository: AnyPublisher<Repository, Never>
    let reloadData: AnyPublisher<Void, Never>
    let updateLoadingView: AnyPublisher<(UIView, Bool), Never>

    private var cancellables = Set<AnyCancellable>()

    init(
        user: User,
        dispatcher: UserRepositoryDispatcher
    ) {
        self.title = "\(user.login)'s Repositories"
        let reloadData = PassthroughSubject<Void, Never>()
        self.selectedRepository = dispatcher.selectedRepository
            .eraseToAnyPublisher()
        self.reloadData = reloadData.eraseToAnyPublisher()
        self.updateLoadingView = dispatcher.updateLoadingView
            .eraseToAnyPublisher()

        $repositories
            .map { _ in }
            .merge(with: $isRepositoryFetching.map { _ in })
            .sink(receiveValue: reloadData.send)
            .store(in: &cancellables)

        dispatcher.countString
            .assign(to: \.countString, on: self)
            .store(in: &cancellables)

        dispatcher.repositories
            .assign(to: \.repositories, on: self)
            .store(in: &cancellables)

        dispatcher.isRepositoryFetching
            .assign(to: \.isRepositoryFetching, on: self)
            .store(in: &cancellables)
    }
}
