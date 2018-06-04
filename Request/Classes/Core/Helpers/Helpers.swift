//
//  Helpers.swift
//  Pods-Request_Tests
//
//  Created by Ivan Petrukha on 04.06.2018.
//

import Foundation

/// Function which unfolds the result and callback about success of the result
public func handle(result: Result<Response, Error>, onSuccess: ((Response) -> Void)? = nil, onError: ((Error) -> Void)? = nil) {
    switch result {
    case let .failure(error):
        onError?(error)
    case let .success(response):
        onSuccess?(response)
    }
}

/// Method which rewrite or supplements dictionary with new objects
public extension Dictionary {
    
    mutating func set(_ objects: Dictionary<Key, Value>, rewrite: Bool) {
        if rewrite {
            self = objects
        } else {
            objects.forEach({ self[$0] = $1 })
        }
    }
}
