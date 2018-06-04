//
//  Response.swift
//  Request
//
//  Created by Ivan Petrukha on 05.03.2018.
//  Copyright © 2018 cellforrow. All rights reserved.
//

import Foundation

/// Typealias which represents JSON format
public typealias JSON = [String : Any]

/// Enumeration which represents any result
public enum Result<Value, Error> {
    
    case success(value: Value)
    case failure(error: Error)
}

public extension Result {
    
    var value: Value? {
        if case let Result.success(value) = self {
            return value
        } else {
            return nil
        }
    }
    
    var error: Error? {
        if case let Result.failure(error) = self {
            return error
        } else {
            return nil
        }
    }
}

/// Struct which represents request response with response data inside
public struct Response {
    
    /// Response data
    public var data: Data
}

/// Converting response data to any model type
extension Response {
    
    func toString(encoding: String.Encoding = .utf8) -> String? {
        return String(data: self.data, encoding: encoding)
    }
    
    func toJSON() -> JSON? {
        return (try? JSONSerialization.jsonObject(with: self.data, options: [])) as? JSON
    }
    
    func toArray() -> [JSON]? {
        return (try? JSONSerialization.jsonObject(with: self.data, options: [])) as? [JSON]
    }
    
    func toObject<T>(_ objectType: T.Type, decoder: JSONDecoder = JSONDecoder()) -> T? where T: Decodable {
        return try? decoder.decode(objectType, from: self.data)
    }
}
