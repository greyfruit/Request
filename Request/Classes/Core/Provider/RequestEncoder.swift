//
//  RequestEncoder.swift
//  Request
//
//  Created by Ivan Petrukha on 05.03.2018.
//  Copyright © 2018 cellforrow. All rights reserved.
//

import Foundation

public protocol RequestEncoderType {
    
    func encode(request: URLRequest, withParameters parameters: HTTPParameters?) throws -> URLRequest
}

public struct RequestEncoder: RequestEncoderType {
    
    static public var auto:     RequestEncoder = RequestEncoder(destination: .methodDependent)
    static public var query:    RequestEncoder = RequestEncoder(destination: .query)
    static public var body:     RequestEncoder = RequestEncoder(destination: .body)
    static public var json:     RequestEncoder = RequestEncoder(destination: .json)
    
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
    
    public func encode(request: URLRequest, withParameters parameters: HTTPParameters?) throws -> URLRequest {
        
        var request = request
        
        guard let parameters = parameters else {
            return request
        }
        
        func queryEncode() {
            
            if let url = request.url, var queryComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
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
