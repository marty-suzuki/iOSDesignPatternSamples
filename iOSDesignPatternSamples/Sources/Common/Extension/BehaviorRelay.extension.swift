//
//  BehaviorRelay.extension.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2019/03/02.
//  Copyright © 2019 marty-suzuki. All rights reserved.
//

import RxCocoa
import RxSwift

extension BehaviorRelay {
    func asObserver() -> AnyObserver<E> {
        return AnyObserver { $0.element.map(self.accept) }
    }
}
