//
//  ApiSession.extension.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2018/01/23.
//  Copyright © 2018年 marty-suzuki. All rights reserved.
//

import GithubKit

extension ApiSession {
    static let shared: ApiSession = {
        let token = "16bae8f74eca2d2d4011f7ea67312898dd6189cb" // <- Your Github Personal Access Token
        return ApiSession(injectToken: { InjectableToken(token: token) })
    }()
}
