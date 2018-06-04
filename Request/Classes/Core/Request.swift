//
//  Request.swift
//  Request
//
//  Created by Ivan Petrukha on 05.03.2018.
//  Copyright © 2018 cellforrow. All rights reserved.
//

import Foundation

/// Typealias which represents result of request completion.
public typealias RequestResult = Result<Response, Error>
/// Typealias closure which represents request completion handler.
public typealias CompletionHandler = ((RequestResult) -> Void)

/// Typealias which represents progress of request executing.
public typealias RequestProgress = Float
/// Typealias closure which represents progress handler of request executing.
public typealias ProgressHandler = ((RequestProgress) -> Void)


/// Typealias which represents parameters of HTTP request.
public typealias HTTPParameters = [String : Any]
/// Typealias which represents headers of HTTP request.
public typealias HTTPHeaders = [String : String]
/// Enum which represents method of HTTP request.
public enum HTTPMethod: String {
    
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
    case patch  = "PATCH"
}

/**
 Basic request container, which helps to build HTTP request, perform it, and handle.
 */
public class Request<RequestTarget: Requestable> {
    
    /**
     Encapsulated class which helps to handle process of request executing.
     */
    private class OperationTaskHandler: OperationTaskDelegate {
        
        /// Queue which be used to callback about events
        var callbackQueue: DispatchQueue?
        
        /// Closure which be used to callback about request completion
        var completionHandler: CompletionHandler?
        
        /// Closure which be used to callback about request progress
        var progressHandler: ProgressHandler?
        
        /// Retry count for request
        var retryCount: Int = 0
    }
    
    private var requestTarget: RequestTarget
    private var operationTaskHandler: OperationTaskHandler
    
    public init(requestTarget: RequestTarget) {
        self.requestTarget = requestTarget
        self.operationTaskHandler = OperationTaskHandler()
    }
    
    public func perform() {
        Provider.shared.perform(
            request: self.requestTarget,
            delegate: self.operationTaskHandler
        )
    }
    
    public func cancel() {
        Provider.shared.cancel(
            request: self.requestTarget
        )
    }
}

/**
 
 Creates **basic** request.
 
 ### Usage Example: ###
 ````
 
 Request
 .plain("http://sample.com/path")
 .perform()
 
 ````
 
 - Parameter url: The path by which the request will be executed.
 - Returns: Request container to build basic HTTP request.
 */
@discardableResult
public func plain(_ url: URLConvertible) -> Request<DataRequest> {
    return Request<DataRequest>(requestTarget: DataRequest(url: url))
}

extension Request {        
    
    
    
    /**
     
     Creates **download** request.
     
     ### Usage Example: ###
     ````
     
     Request
         .download(from: "http://sample.com/image.jpg")
         .perform()
     
     ````
     
     - Parameter downloadURL: The path by which the data will be downloaded.
     - Parameter destinationURL: The path where data will be saved.
     - Returns: Request container to build download HTTP request.
     */
    @discardableResult
    static func download(from downloadURL: URLConvertible, to destinationURL: URLConvertible? = nil) -> Request<DownloadRequest> {
        return Request<DownloadRequest>(requestTarget: DownloadRequest(downloadURL: downloadURL, destinationURL: destinationURL))
    }
    
    /**
     
     Creates **upload** request.
     
     ### Usage Example: ###
     ````
     
     Request
         .upload(file: "Documents/Images/avatar.jpeg", to: "http://sample.com/upload/userAvatar")
         .perform()
     
     ````
     
     - Parameter fileURL: The path of file which be uploaded.
     - Parameter destinationURL: The path where data will be uploaded.
     - Returns: Request container to build upload HTTP request.
     */
    @discardableResult
    static func upload(file fileURL: URLConvertible, to destinationURL: URLConvertible) -> Request<UploadRequest> {
        return Request<UploadRequest>(requestTarget: UploadRequest(fileURL: fileURL, destinationURL: destinationURL))
    }
    
    /**
     
     Creates **upload** request.
     
     ### Usage Example: ###
     ````
     
     Request
         .upload(data: imageData, to: "http://sample.com/upload/userAvatar")
         .perform()
     
     ````
     
     - Parameter fileURL: The path of file which be uploaded.
     - Parameter destinationURL: The path where data will be uploaded.
     - Returns: Request container to build upload HTTP request.
     */
    @discardableResult
    static func upload(data fileData: Data, to destinationURL: URLConvertible) -> Request<UploadRequest> {
        return Request<UploadRequest>(requestTarget: UploadRequest(fileData: fileData, destinationURL: destinationURL))
    }
    
    /**
     
     Creates **upload** request.
     
     ### Usage Example: ###
     ````
     
     Request
         .multipart(multipartFormData: {
             $0.append(fileData: imageData, fieldName: "userAvatar", fileName: "avatar.jpeg", mimeType: "image/jpeg")
             $0.append(fileData: instructionsData, fieldName: "instructions", fileName: "instructions.pdf", mimeType: "application/pdf")
         }, to: "http://sample.com/uploadResources")
         .perform()
     
     ````
     
     - Parameter fileURL: The path of file which be uploaded.
     - Parameter destinationURL: The path where data will be uploaded.
     - Returns: Request container to build upload HTTP request.
     */
    @discardableResult
    static func multipart(multipartFormData: MultipartRequest.MultipartFormDataPreparation, to destinationURL: URLConvertible) -> Request<MultipartRequest> {
        return Request<MultipartRequest>(requestTarget: MultipartRequest(multipartFormDataPreparation: multipartFormData, destinationURL: destinationURL))
    }
}

extension Request {
    
    @discardableResult
    func retry(_ retryCount: Int) -> Self {
        
        self.operationTaskHandler.retryCount = retryCount
        
        return self
    }
    
    @discardableResult
    func callbackQueue(_ queue: DispatchQueue) -> Self {
        
        self.operationTaskHandler.callbackQueue = queue
        
        return self
    }
    
    @discardableResult
    func progress(_ progressHandler: @escaping ProgressHandler) -> Self {
        
        self.operationTaskHandler.progressHandler = progressHandler
        
        return self
    }
    
    @discardableResult
    func completion(_ completionHandler: @escaping CompletionHandler) -> Self {
        
        self.operationTaskHandler.completionHandler = completionHandler
        
        return self
    }
}

public class DataRequest: Requestable {
    
    public var url: URLConvertible
    public var method: HTTPMethod
    public var parameters: HTTPParameters?
    public var headers: HTTPHeaders?
    public var encoder: RequestEncoderType?
    
    public init(url: URLConvertible, method: HTTPMethod = .get, parameters: HTTPParameters? = nil, headers: HTTPHeaders? = nil) {
        self.url = url
        self.method = method
        self.parameters = parameters
        self.headers = headers
    }
    
    public func asURLRequest() throws -> URLRequest {
        
        let url = try self.url.asURL()
        var request = URLRequest(url: url)
        request.httpMethod = self.method.rawValue
        request.allHTTPHeaderFields = self.headers
        
        let encoder = self.encoder ?? RequestEncoder.auto
        
        return try encoder.encode(request: request, withParameters: self.parameters)
    }
    
    public func asURLSessionTask(session: URLSession) throws -> URLSessionTask {
        
        let request = try self.asURLRequest()
        
        return session.dataTask(with: request)
    }
}

extension Request where RequestTarget: DataRequest {
    
    @discardableResult
    func method(_ method: HTTPMethod) -> Self {

        self.requestTarget.method = method

        return self
    }
    
    @discardableResult
    func parameters(_ parameters: HTTPParameters, rewrite: Bool = false) -> Self {

        self.requestTarget.parameters = parameters

        return self
    }

    @discardableResult
    func headers(_ headers: HTTPHeaders, rewrite: Bool = false) -> Self {

        if rewrite {
            self.requestTarget.headers = headers
        } else {
            if self.requestTarget.headers == nil {
                self.requestTarget.headers = headers
            } else {
                headers.forEach({ self.requestTarget.headers![$0] = $1 })
            }
        }

        return self
    }   
    
    @discardableResult
    func encoding(_ encoder: RequestEncoder) -> Self {

        self.requestTarget.encoder = encoder

        return self
    }
}

class DownloadRequest: DataRequest {
    
    init(downloadURL: URLConvertible, destinationURL: URLConvertible?) {
        super.init(url: downloadURL)
    }
    
    override public func asURLSessionTask(session: URLSession) throws -> URLSessionTask {
        
        let request = try self.asURLRequest()
        
        return session.downloadTask(with: request)
    }
}

public class UploadRequest: DataRequest {
    
    enum UploadType {
        case file(url: URLConvertible)
        case data(data: Data)
    }
    
    private(set) var uploadType: UploadType
    
    public var fileName:   String = Int(Date().timeIntervalSince1970).string
    public var fieldName:  String = "userfile"
    public var mimeType:   String = "application/json"
    
    init(fileURL: URLConvertible, destinationURL: URLConvertible) {
        
        self.uploadType = .file(url: fileURL)
        
        super.init(url: destinationURL, method: .post)
    }
    
    init(fileData: Data, destinationURL: URLConvertible) {
        
        self.uploadType = .data(data: fileData)
        
        super.init(url: destinationURL, method: .post)
    }
    
    public override func asURLRequest() throws -> URLRequest {
        
        var request = try super.asURLRequest()
        
        request.setValue("\(self.mimeType)", forHTTPHeaderField: "Content-Type")
        request.setValue("attachment; filename=\"\(self.fileName)\"", forHTTPHeaderField: "Content-Disposition")
        
        return request
    }
    
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

public extension Request where RequestTarget: UploadRequest {
    
    @discardableResult
    public func fileName(_ fileName: String) -> Self {
        
        self.requestTarget.fileName = fileName
        
        return self
    }
    
    @discardableResult
    public func fieldName(_ fieldName: String) -> Self {
        
        self.requestTarget.fieldName = fieldName
        
        return self
    }
    
    @discardableResult
    public func mimeType(_ mimeType: String) -> Self {
        
        self.requestTarget.mimeType = mimeType
        
        return self
    }
}

public class MultipartRequest: DataRequest {
    
    public typealias MultipartFormDataPreparation = ((MultipartFormData) -> Void)
    
    private let multipartFormData: MultipartFormData
    
    public init(multipartFormDataPreparation: MultipartFormDataPreparation, destinationURL: URLConvertible) {
        
        let multipartFormData = MultipartFormData()
        
        multipartFormDataPreparation(multipartFormData)
        
        self.multipartFormData = multipartFormData
        
        super.init(url: destinationURL, method: .post)
    }
    
    public class MultipartFormData {
        
        struct EncodingCharacters {
            static let crlf = "\r\n"
        }
        
        private var boundary: String = UUID().uuidString
        
        private class BodyPart {
            
            enum PartPosition {
                case initial
                case encapsulated
                case final
            }
            
            public var partPosition: PartPosition = .encapsulated
            
            private(set) var fileData:   Data
            private(set) var fileName:   String = Int(Date().timeIntervalSince1970).string
            private(set) var fieldName:  String = "userfile"
            private(set) var mimeType:   String = "application/json"
            
            init(fileData: Data, fieldName: String, fileName: String, mimeType: String) {
                self.fileData = fileData
                self.fieldName = fieldName
                self.fileName = fileName
                self.mimeType = mimeType
            }
            
            private func boundaryStartString(boundary: String) -> String {
                return "--\(boundary)" + EncodingCharacters.crlf
            }
            
            private func boundaryEncapsulatedString(boundary: String) -> String {
                return EncodingCharacters.crlf + "--\(boundary)" + EncodingCharacters.crlf
            }
            
            private func boundaryEndString(boundary: String) -> String {
                return EncodingCharacters.crlf + "--\(boundary)--" + EncodingCharacters.crlf
            }
            
            private func contentDispositionString() -> String {
                return "Content-Disposition: form-data; name=\"\(self.fieldName)\"; filename=\"\(self.fileName)\"" + EncodingCharacters.crlf
            }
            
            private func contentTypeString() -> String {
                return "Content-Type: \(self.mimeType)" + EncodingCharacters.crlf + EncodingCharacters.crlf
            }
            
            public func write(to data: inout Data, boundary: String) throws {
                
                if case PartPosition.initial = self.partPosition {
                    data.append(try self.boundaryStartString(boundary: boundary).asData())
                } else {
                    data.append(try self.boundaryEncapsulatedString(boundary: boundary).asData())
                }
                
                data.append(try self.contentDispositionString().asData())
                data.append(try self.contentTypeString().asData())
                data.append(try self.fileData.asData())
                data.append(try EncodingCharacters.crlf.asData())
                
                if case PartPosition.final = self.partPosition {
                    data.append(try self.boundaryEndString(boundary: boundary).asData())
                }
            }
        }
        
        private var bodyParts: [BodyPart] = []
        
        public func append(fileData: Data, fieldName: String, fileName: String, mimeType: String) {
            self.bodyParts.append(.init(fileData: fileData, fieldName: fieldName, fileName: fileName, mimeType: mimeType))
        }
        
        public func encode(request: URLRequest) throws -> URLRequest {
            
            var request = request
            
            request.setValue("multipart/form-data; boundary=\(self.boundaryString())", forHTTPHeaderField: "Content-Type")
            
            try request.httpBody = {
                
                var data = Data()
                let boundary = self.boundaryString()
                
                self.bodyParts.first?.partPosition = .initial
                self.bodyParts.last?.partPosition = .final
                
                try self.bodyParts.forEach({
                    try $0.write(to: &data, boundary: boundary)
                })
                
                return data
            }()
            
            return request
        }
        
        private func boundaryString() -> String {
            return "Boundary-\(self.boundary)"
        }
    }
    
    override public func asURLRequest() throws -> URLRequest {
        return try self.multipartFormData.encode(request: try super.asURLRequest())
    }
}
