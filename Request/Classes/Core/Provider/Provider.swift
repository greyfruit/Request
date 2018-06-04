//
//  Provider.swift
//  Request
//
//  Created by Ivan Petrukha on 05.03.2018.
//  Copyright © 2018 cellforrow. All rights reserved.
//

import Foundation

/// Protocol of request executing process delegating
public protocol OperationTaskDelegate {
    
    var completionHandler: CompletionHandler? { get }
    var progressHandler: ProgressHandler? { get }
    var callbackQueue: DispatchQueue? { get }
    var retryCount: Int { get }
}

/**
 Basic request provider which can perform requests and handle network responses
 */
public class Provider: NSObject {
    
    /// Default provider
    public static let shared: Provider = Provider()
    
    /// Provider executing errors
    public enum ProviderError: Error {
        case unknown
    }
    
    /// Request response handler
    private var responseHandler: ResponseHandler = ResponseHandler()
    /// Queue where operations will be performed
    private var operationQueue:  OperationQueue = OperationQueue()
    /// Current executing operation tasks
    private var operationTasks:  [OperationTask] = []
    /// Default provider URLSession
    private(set) lazy var session: URLSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: self.operationQueue
    )
}

extension Provider {
    
    /**
     Class which represents request performing in action
     */
    public class OperationTask: NSObject {
        
        /// Executing process delegate
        private(set) var delegate: OperationTaskDelegate
        
        private(set) var originalRequest: Requestable
        private(set) var sessionTask: URLSessionTask
        private(set) var request: URLRequest
        
        /// Attempts left to retry
        public var retryCount: Int = 0
        /// Buffer data, where the loaded bytes are written
        public var buffer: Data = Data()
        /// Request response object
        public var response: URLResponse?
        /// Callback queue
        public var callbackQueue: DispatchQueue {
            return self.delegate.callbackQueue ?? .global(qos: .background)
        }
        
        init(request: Requestable, session: URLSession, delegate: OperationTaskDelegate) throws {
            
            self.originalRequest = request
            self.sessionTask = try request.asURLSessionTask(session: session)
            self.request = try request.asURLRequest()
            
            self.delegate = delegate
            self.retryCount = delegate.retryCount
        }
        
        /// Method which notify delegate about current progress
        public func progress(_ progress: Float) {
            if let progressHandler = self.delegate.progressHandler {
                self.callbackQueue.async {
                    progressHandler(progress)
                }
            }
        }
        
        /// Method which notify delegate about request executing completion
        public func completion(_ result: Result<Response, Error>) {
            
            defer {
                self.progress(1.0)
            }
            
            if let completionHandler = self.delegate.completionHandler {
                self.callbackQueue.async {
                    completionHandler(result)
                }
            }
        }
        
        /// Method which try to retry operation task in failure case
        public func retry(session: URLSession) {
            do {
                
                self.retryCount -= 1
                
                self.sessionTask = try self.originalRequest.asURLSessionTask(session: session)
                self.sessionTask.resume()
                
            } catch {
                if let completionHandler = self.delegate.completionHandler {
                    completionHandler(.failure(error: error))
                }
            }
        }
    }
}

extension Provider {
    
    /// Method which try to perform request
    public func perform(request: Requestable, delegate: OperationTaskDelegate) {
        do {
            
            let operationTask = try OperationTask(request: request, session: self.session, delegate: delegate)
            
            self.operationTasks.append(operationTask)
            
            operationTask.sessionTask.resume()
            
        } catch {
            if let completionHandler = delegate.completionHandler {
                completionHandler(.failure(error: error))
            }
        }
    }
        
    /// Method which cancel request if exists
    public func cancel(request: Requestable) {
        
        guard let request = try? request.asURLRequest() else {
            return
        }
        
        if let operationTask = self.operationTasks.first(where: { $0.request == request }) {
            
            defer {
                operationTask.sessionTask.cancel()
            }
            
            if let operationTaskIndex = self.operationTasks.index(of: operationTask) {
                
                self.operationTasks.remove(at: operationTaskIndex)
            }
        }
    }
}

/**
 Conforming provider to URLSessionDelegate
 */
extension Provider: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    
    /// On recieve data task response set operation task response and allow executing
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        defer {            
            completionHandler(.allow)
        }

        guard let operationTask = self.operationTasks.first(where: { $0.sessionTask === dataTask }) else {
            return
        }

        operationTask.response = response
    }
    
    /// On finish downloading get data from location and set it in operation task buffer
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let operationTask = self.operationTasks.first(where: { $0.sessionTask === downloadTask }) else {
            return
        }
        
        if let data = try? Data(contentsOf: location) {
            operationTask.buffer = data
        }
    }
    
    /// On write downloaded bytes determine the percentage of progress and notify delegate
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard let operationTask = self.operationTasks.first(where: { $0.sessionTask === downloadTask }) else {
            return
        }
        
        let progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
        
        operationTask.progress(progress)
    }
    
    /// On sent bytes to network determine the percentage of progress and notify delegate
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        guard let operationTask = self.operationTasks.first(where: { $0.sessionTask === task }) else {
            return
        }
        
        let progress = Float(totalBytesSent)/Float(totalBytesExpectedToSend)
        
        operationTask.progress(progress)
    }
    
    /// On recieve part of response data save it to operation task buffer
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        guard let operationTask = self.operationTasks.first(where: { $0.sessionTask === dataTask }) else {
            return
        }

        operationTask.buffer = data
    }
        
    /// On completion executing trying to retry if fails, else notifiy delegate about completion
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        guard let operationTask = self.operationTasks.first(where: { $0.sessionTask === task }) else {
            return
        }
        
        defer {
            self.operationTasks = self.operationTasks.filter({ $0.sessionTask !== task })
        }
        
        let result = self.responseHandler.handle(data: operationTask.buffer, response: operationTask.response, error: error)
        
        if case Result.failure = result, operationTask.retryCount > 0 {
            operationTask.retry(session: self.session)
        } else {
            operationTask.completion(result)
        }
    }
}
