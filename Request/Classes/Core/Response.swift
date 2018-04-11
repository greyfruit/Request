//
//  Response.swift
//  Request
//
//  Created by Ivan Petrukha on 05.03.2018.
//  Copyright © 2018 cellforrow. All rights reserved.
//

import Foundation

public typealias JSON = [String : Any]

public enum Result<T, E> {
    
    case success(value: T)
    case failure(error: E)
    
    var value: T? {
        if case let Result.success(value) = self {
            return value
        } else {
            return nil
        }
    }
    
    var error: E? {
        if case let Result.failure(error) = self {
            return error
        } else {
            return nil
        }
    }
}

public struct Response {
    
    public var data: Data
    
    public func toString(encoding: String.Encoding = .utf8) -> String? {
        return String(data: self.data, encoding: encoding)
    }
    
    public func toJSON() -> JSON? {
        return (try? JSONSerialization.jsonObject(with: self.data, options: [])) as? JSON
    }
    
    public func toArray() -> [JSON]? {        
        return (try? JSONSerialization.jsonObject(with: self.data, options: [])) as? [JSON]
    }
    
    public func toObject<T>(_ objectType: T.Type, decoder: JSONDecoder = JSONDecoder()) -> T? where T: Decodable {
        return try? decoder.decode(objectType, from: self.data)
    }
}
