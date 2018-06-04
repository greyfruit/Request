//
//  UploadRequest.swift
//  Request
//
//  Created by Ivan Petrukha on 04.06.2018.
//

import Foundation

/**
 Basic request target which can be used for upload requests
 */
public class UploadRequest: DataRequest {
    
    /**
     Enumeration which represents upload way, upload request can only upload single object for request
     */
    enum UploadType {
        
        /// File uploading
        case file(url: URLConvertible)
        
        /// File data uploading
        case data(data: Data)
    }
    
    private(set) var uploadType: UploadType
    
    public var fileName:   String = "\(Int(Date().timeIntervalSince1970))"
    public var fieldName:  String = "userfile"
    public var mimeType:   String = "application/json"
    
    /// Initializer for file uploading
    init(fileURL: URLConvertible, destinationURL: URLConvertible) {
        
        self.uploadType = .file(url: fileURL)
        
        super.init(url: destinationURL, method: .post)
    }
    
    /// Initializer for file data uploading
    init(fileData: Data, destinationURL: URLConvertible) {
        
        self.uploadType = .data(data: fileData)
        
        super.init(url: destinationURL, method: .post)
    }
    
    /**
     Custom converting to URLRequest object
     */
    public override func asURLRequest() throws -> URLRequest {
        
        var request = try super.asURLRequest()
            request.setValue("\(self.mimeType)", forHTTPHeaderField: "Content-Type")
            request.setValue("attachment; filename=\"\(self.fileName)\"", forHTTPHeaderField: "Content-Disposition")
        
        return request
    }
    
    /**
     Custom converting to URLSessionTask object
     */
    override public func asURLSessionTask(session: URLSession) throws -> URLSessionTask {
        
        let request = try self.asURLRequest()
        
        switch self.uploadType {
        case let .file(url):
            return session.uploadTask(with: request, fromFile: try url.asURL())
        case let .data(data):
            return session.uploadTask(with: request, from: data)
        }
    }
}


