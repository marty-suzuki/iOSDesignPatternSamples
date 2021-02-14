//
//  ApiSession.extension.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2018/01/23.
//  Copyright © 2018年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit

extension ApiSession {
    static let shared: ApiSession = {
        let token = "" // <- Your Github Personal Access Token
        return ApiSession(injectToken: { InjectableToken(token: token) })
    }()
}

typealias SendRequest<T: Request> = (T) -> AnyPublisher<T.ResponseType, Swift.Error>
