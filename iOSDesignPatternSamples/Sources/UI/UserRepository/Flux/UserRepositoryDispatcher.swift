//
//  UserRepositoryDispatcher.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import GithubKit
import UIKit

final class UserRepositoryDispatcher {
    let selectedRepository = PassthroughSubject<Repository, Never>()
    let updateLoadingView = PassthroughSubject<(UIView, Bool), Never>()
    let countString = PassthroughSubject<String, Never>()
    let repositories = PassthroughSubject<[Repository], Never>()
    let isRepositoryFetching = PassthroughSubject<Bool, Never>()
}
