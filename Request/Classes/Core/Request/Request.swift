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
public class Request<RequestTarget: DataRequest> {
    
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
}

/**
 Request executing
 */
public extension Request {
    
    /**
     Function which start executing of request in default provider
     */
    @discardableResult
    func perform() -> Self {
        
        Provider.shared.perform(
            request: self.requestTarget,
            delegate: self.operationTaskHandler
        )
        
        return self
    }
    
    /**
     Function which canceling executing of request
     */
    func cancel() {
        Provider.shared.cancel(
            request: self.requestTarget
        )
    }
}

public extension Request {
    
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
    static func plain(_ url: URLConvertible) -> Request<DataRequest> {
        return Request<DataRequest>(
            requestTarget: DataRequest(
                url: url
            )
        )
    }
    
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
        return Request<DownloadRequest>(
            requestTarget: DownloadRequest(
                downloadURL: downloadURL,
                destinationURL: destinationURL
            )
        )
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
        return Request<UploadRequest>(
            requestTarget: UploadRequest(
                fileURL: fileURL,
                destinationURL: destinationURL
            )
        )
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
        return Request<UploadRequest>(
            requestTarget: UploadRequest(
                fileData: fileData,
                destinationURL: destinationURL
            )
        )
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
        return Request<MultipartRequest>(
            requestTarget: MultipartRequest(
                multipartFormDataPreparation: multipartFormData,
                destinationURL: destinationURL
            )
        )
    }
}

/**
 Operation task handler builder
 */
public extension Request {
    
    /**
     Set attempts to retry.
     
     ### Usage Example: ###
     ````
     
     Request
        .plain("http://sample.com/get")
        .retry(3)
        .perform()
     
     ````
     
     - Parameter retryCount: Number of attempts for request.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    func retry(_ retryCount: Int) -> Self {
        
        self.operationTaskHandler.retryCount = retryCount
        
        return self
    }
    
    /**
     Set callback DispatchQueue.
     
     ### Usage Example: ###
     ````
     
     Request
         .plain("http://sample.com/get")
         .callbackQueue(DispatchQueue.main)
         .progress({ print($0) }) // Will be called on main queue
         .perform()
     
     ````
     
     - Parameter queue: DispatchQueue where callback will be called.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    func callbackQueue(_ queue: DispatchQueue) -> Self {
        
        self.operationTaskHandler.callbackQueue = queue
        
        return self
    }
    
    /**
     Set progress closure.
     
     ### Usage Example: ###
     ````
     
     Request
         .plain("http://sample.com/get")
         .progress({ print($0) })
         .perform()
     
     ````
     
     - Parameter progressHandler: Closure which be called each time when progress changed.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    func progress(_ progressHandler: @escaping ProgressHandler) -> Self {
        
        self.operationTaskHandler.progressHandler = progressHandler
        
        return self
    }
    
    /**
     Set completion closure.
     
     ### Usage Example: ###
     ````
     
     Request
         .plain("http://sample.com/get")
         .completion({ result in
            print(result.value)
         })
         .perform()
     
     ````
     
     - Parameter completionHandler: Closure which be called when request end executing.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    func completion(_ completionHandler: @escaping CompletionHandler) -> Self {
        
        self.operationTaskHandler.completionHandler = completionHandler
        
        return self
    }
}

/**
 Data request builder
 */
public extension Request where RequestTarget: DataRequest {
    
    /**
     Set HTTP method of request.
     
     ### Usage Example: ###
     ````
     
     Request
         .plain("http://sample.com/get")
         .method(.get)
         .perform()
     
     ````
     
     - Parameter method: HTTPMethod of request.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    func method(_ method: HTTPMethod) -> Self {

        self.requestTarget.method = method

        return self
    }

    /**
     Set parameters of request.
     
     ### Usage Example: ###
     ````
     
     Request
         .plain("http://sample.com/get")
         .method(.get)
         .parameters(["username":"user1235"]
         .perform()
     
     ````
     
     - Parameter parameters: Parameters of request.
     - Parameter rewrite: Flag if existing parameters should being overrided.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    func parameters(_ parameters: HTTPParameters, rewrite: Bool = false) -> Self {
        
        if self.requestTarget.parameters == nil {
            self.requestTarget.parameters = parameters
        } else {
            self.requestTarget.parameters?.set(parameters, rewrite: rewrite)
        }

        return self
    }

    /**
     Set parameters of request.
     
     ### Usage Example: ###
     ````
     
     Request
         .plain("http://sample.com/get")
         .method(.get)
         .parameters(["username":"user1235"]
         .headers(["token":"g7ak1p1vS9a23fSa3"]
         .perform()
     
     ````
     
     - Parameter headers: Headers of request.
     - Parameter rewrite: Flag if existing headers should being overrided.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    func headers(_ headers: HTTPHeaders, rewrite: Bool = false) -> Self {

        if self.requestTarget.headers == nil {
            self.requestTarget.headers = headers
        } else {
            self.requestTarget.headers?.set(headers, rewrite: rewrite)
        }

        return self
    }
    
    /**
     Set encoding of request.
     
     ### Usage Example: ###
     ````
     
     Request
         .plain("http://sample.com/get")
         .method(.get)
         .parameters(["username":"user1235"]
         .perform()
     
     ````
     
     - Parameter encoder: Encoder of request. There few default encoders RequestEncoder.query, .body, .json and .auto which depends of request HTTPMethod.
     - Parameter rewrite: Flag if existing parameters should being overrided.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    func encoding(_ encoder: RequestEncoder) -> Self {
        
        self.requestTarget.encoder = encoder

        return self
    }
}

/**
 Upload task builder
 */
public extension Request where RequestTarget: UploadRequest {
    
    /**
     Set file name of data.
     
     ### Usage Example: ###
     ````
     
     Request
         .upload(data: imageData, to: "http://sample.com/upload/avatar")
         .fileName("avatar.jpeg")
         .perform()
     
     ````
     
     - Parameter fileName: File name of file data.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    public func fileName(_ fileName: String) -> Self {
        
        self.requestTarget.fileName = fileName
        
        return self
    }
    
    /**
     Set field name of data.
     
     ### Usage Example: ###
     ````
     
     Request
         .upload(data: imageData, to: "http://sample.com/upload/avatar")
         .fieldName("avatar")
         .perform()
     
     ````
     
     - Parameter fieldName: Field name of file data.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    public func fieldName(_ fieldName: String) -> Self {
        
        self.requestTarget.fieldName = fieldName
        
        return self
    }
    
    /**
     Set mime type of data.
     
     ### Usage Example: ###
     ````
     
     Request
         .upload(data: imageData, to: "http://sample.com/upload/avatar")
         .mimeType("image/jpeg")
         .perform()
     
     ````
     
     - Parameter mimeType: Mime type of file data.
     - Returns: Request container to continue building request.
     */
    @discardableResult
    public func mimeType(_ mimeType: String) -> Self {
        
        self.requestTarget.mimeType = mimeType
        
        return self
    }
}
