//
//  ResponseHandler.swift
//  Request
//
//  Created by Ivan Petrukha on 05.03.2018.
//  Copyright © 2018 cellforrow. All rights reserved.
//

import Foundation

public func handle(result: Result<Response, Error>, onSuccess: ((Response) -> Void)? = nil, onError: ((Error) -> Void)? = nil) {
    switch result {
    case let .failure(error):
        onError?(error)
    case let .success(response):
        onSuccess?(response)
    }
}

enum ResponseHandlerError: Error {
    case url
    case statusCode
    case unknown
}

public protocol ResponseHandlerType {
    
    func handle(data: Data?, response: URLResponse?, error: Error?) -> Result<Response, Error>
}

public struct ResponseHandler: ResponseHandlerType {
    
    public init() {
        
    }
    
    private func snatch(_ error: Error?) throws {
        if let error = error as? URLError {
            switch error.code {
            case URLError.Code.badURL:
                throw ResponseHandlerError.url
            default:
                throw ResponseHandlerError.unknown
            }
        }
    }
    
    private func validate(_ response: URLResponse?) throws {
        
        guard let response = response as? HTTPURLResponse else {
            return
        }
        
        guard (200...299).contains(response.statusCode) else {
            throw ResponseHandlerError.statusCode
        }
    }
    
    private func compose(_ data: Data?) throws -> Response {
        
        guard let data = data else {
            throw ResponseHandlerError.unknown
        }
        
        return Response(data: data)
    }
    
    public func handle(data: Data?, response: URLResponse?, error: Error?) -> Result<Response, Error> {
        do {
            
            try self.snatch(error)
            try self.validate(response)
            
            return Result.success(value: try self.compose(data))
            
        } catch (let handlerError) {
            return Result.failure(error: error ?? handlerError)
        }
    }
}
