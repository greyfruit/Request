//
//  DataRequest.swift
//  Request
//
//  Created by Ivan Petrukha on 04.06.2018.
//

import Foundation

/**
 Basic request target which can be used for plain requests
 */
public class DataRequest: Requestable { /// Data request conforms Requestable protocol which means data request can be performed by the system
    
    /// URL path by which request will perform
    public var url: URLConvertible
    /// Request HTTTP method
    public var method: HTTPMethod
    /// Request parameters
    public var parameters: HTTPParameters?
    /// Request headers
    public var headers: HTTPHeaders?
    /// Request Encoder, by defaults its automatic and depends on HTTP method
    public var encoder: RequestEncoderType = RequestEncoder.auto
    
    public init(url: URLConvertible, method: HTTPMethod = .get, parameters: HTTPParameters? = nil, headers: HTTPHeaders? = nil) {
        self.url = url
        self.method = method
        self.parameters = parameters
        self.headers = headers
    }
    
    /**
     Converting data request to URLRequest object
     */
    public func asURLRequest() throws -> URLRequest {
        
        let url = try self.url.asURL()
        var request = URLRequest(url: url)
            request.httpMethod = self.method.rawValue
            request.allHTTPHeaderFields = self.headers
        
        return try self.encoder.encode(request: request, withParameters: self.parameters)
    }
    
    /**
     Converting data request to URLSessionTask object
     */
    public func asURLSessionTask(session: URLSession) throws -> URLSessionTask {
        
        let request = try self.asURLRequest()
        
        return session.dataTask(with: request)
    }
}
