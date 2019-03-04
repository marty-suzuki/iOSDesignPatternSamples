//
//  Value.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2018/01/24.
//  Copyright © 2018年 marty-suzuki. All rights reserved.
//

import Foundation

struct Value<Base> {
    let base: Base
}

protocol ValueCompatible {
    var value: Value<Self> { get }
}

extension ValueCompatible {
    var value: Value<Self> {
        return Value(base: self)
    }
}
