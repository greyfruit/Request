//
//  Requestable.swift
//  Request
//
//  Created by Ivan Petrukha on 03.04.2018.
//  Copyright © 2018 cellforrow. All rights reserved.
//

import Foundation

public typealias Requestable = URLRequestConvertible & URLSessionTaskConvertible

public enum URLConvertibleError: Error {
    case unknown
}

public protocol URLConvertible {
    func asURL() throws -> URL
}

public protocol URLRequestConvertible {
    func asURLRequest() throws -> URLRequest
}

public protocol URLSessionTaskConvertible {
    func asURLSessionTask(session: URLSession) throws -> URLSessionTask
}

extension String: URLConvertible {
    public func asURL() throws -> URL {
        
        guard let url = URL(string: self) else {
            throw URLConvertibleError.unknown
        }
        
        return url
    }
}

extension URL: URLConvertible {
    public func asURL() throws -> URL {
        return self
    }
}
