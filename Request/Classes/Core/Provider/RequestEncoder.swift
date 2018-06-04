//
//  RequestEncoder.swift
//  Request
//
//  Created by Ivan Petrukha on 05.03.2018.
//  Copyright © 2018 cellforrow. All rights reserved.
//

import Foundation

/// Protocol which represents request encoder object
public protocol RequestEncoderType {
    
    func encode(request: URLRequest, withParameters parameters: HTTPParameters?) throws -> URLRequest
}

/**
 Basic request encoder
 */
public struct RequestEncoder: RequestEncoderType {
    
    /// Automatic encoding depends on HTTP method of request
    static public var auto:     RequestEncoder = RequestEncoder(destination: .methodDependent)
    /// Query encoding in request url string as url parameters
    static public var query:    RequestEncoder = RequestEncoder(destination: .query)
    /// Body encoding in request body as url parameters
    static public var body:     RequestEncoder = RequestEncoder(destination: .body)
    /// JSON encoding in request body as json format
    static public var json:     RequestEncoder = RequestEncoder(destination: .json)
    
    /// Encoding type
    public enum Destination {
        case methodDependent
        case query
        case body
        case json
    }
    
    private(set) var destination: Destination
    
    private init(destination: Destination) {
        self.destination = destination
    }
    
    /// Method which modify input request and returns encoded request
    public func encode(request: URLRequest, withParameters parameters: HTTPParameters?) throws -> URLRequest {
        
        var request = request
        
        guard let parameters = parameters else {
            return request
        }
        
        func queryEncode() {
            
            if let url = request.url, let queryComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
//                queryComponents.percentEncodedQuery = (queryComponents.percentEncodedQuery.map({ $0 + "&" }) ?? String.empty) + self.query(parameters: parameters)
                request.url = queryComponents.url
            }
        }
        
        func bodyEncode() {
            
            if request.value(forHTTPHeaderField: "content-type") == nil {
                request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "content-type")
            }
            
            request.httpBody = self.query(parameters: parameters).data(using: .utf8, allowLossyConversion: false)
        }
        
        func jsonEncode() {
            
            if request.value(forHTTPHeaderField: "content-type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "content-type")
            }
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }
        
        switch self.destination {
        case .methodDependent:
            if (request.httpMethod ?? "" == "GET") { queryEncode() } else { bodyEncode() }
        case .query:
            queryEncode()
        case .body:
            bodyEncode()
        case .json:
            jsonEncode()
        }
        
        return request
    }
    
    private func query(parameters: HTTPParameters) -> String {
        return parameters
            .compactMap({ "\($0)=\($1)" })
            .joined(separator: "&")
    }
}
