//
//  DownloadRequest.swift
//  Request
//
//  Created by Ivan Petrukha on 04.06.2018.
//

import Foundation

/**
 Basic request target which can be used for download requests
 */
public class DownloadRequest: DataRequest {
    
    init(downloadURL: URLConvertible, destinationURL: URLConvertible?) {
        super.init(url: downloadURL)
    }
    
    /**
     Custom converting to URLSessionTask object
     */
    override public func asURLSessionTask(session: URLSession) throws -> URLSessionTask {
        
        let request = try self.asURLRequest()
        
        return session.downloadTask(with: request)
    }
}
