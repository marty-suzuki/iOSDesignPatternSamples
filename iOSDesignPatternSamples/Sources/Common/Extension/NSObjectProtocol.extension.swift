//
//  NSObjectProtocol.extension.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2018/01/23.
//  Copyright © 2018年 marty-suzuki. All rights reserved.
//

import Foundation

extension NSObjectProtocol {
    static var className: String {
        return String(describing: self)
    }
}
