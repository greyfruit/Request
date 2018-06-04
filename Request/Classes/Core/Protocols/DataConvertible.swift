//
//  DataConvertible.swift
//  Request
//
//  Created by Ivan Petrukha on 06.04.2018.
//  Copyright © 2018 cellforrow. All rights reserved.
//

import Foundation

/// Protocol which represents data convertible object
protocol DataConvertible {
    func asData() throws -> Data
}

extension String: DataConvertible {
    func asData() throws -> Data {
        
        guard let data = self.data(using: .utf8, allowLossyConversion: true) else {
            throw URLConvertibleError.unknown
        }
        
        return data
    }
}

extension Data: DataConvertible {
    func asData() throws -> Data {
        return self
    }
}
