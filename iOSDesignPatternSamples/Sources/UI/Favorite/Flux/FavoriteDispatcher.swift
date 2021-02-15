//
//  FavoriteDispatcher.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import GithubKit

final class FavoriteDispatcher {
    let favorites = PassthroughSubject<[Repository], Never>()
    let selectedRepository = PassthroughSubject<Repository, Never>()
}
