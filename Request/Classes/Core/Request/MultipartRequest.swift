//
//  MultipartRequest.swift
//  Request
//
//  Created by Ivan Petrukha on 04.06.2018.
//

import Foundation

/**
 Basic request target which can be used for multipart requests
 */
public class MultipartRequest: DataRequest {
    
    /// Typealias which represents multipart form data preparation
    public typealias MultipartFormDataPreparation = ((MultipartFormData) -> Void)
    
    /// Multipart form data
    private let multipartFormData: MultipartFormData
    
    /// Initializer which takes input multipart preparation, creates new multipart object and modifies it with preparation
    public init(multipartFormDataPreparation: MultipartFormDataPreparation, destinationURL: URLConvertible) {
        
        let multipartFormData = MultipartFormData()
        
        multipartFormDataPreparation(multipartFormData)
        
        self.multipartFormData = multipartFormData
        
        super.init(url: destinationURL, method: .post)
    }
    
    /**
     Custom converting to URLRequest object
     */
    override public func asURLRequest() throws -> URLRequest {
        
        let request = try super.asURLRequest()
        
        return try self.multipartFormData.encode(request: request)
    }
}

extension MultipartRequest {
    
    /**
     Class which contains multipart form data parts and encode it to request
     */
    public class MultipartFormData {
        
        struct EncodingCharacters {
            static let crlf = "\r\n"
        }
        
        /// Body parts consisting multipart form data
        private var bodyParts: [BodyPart] = []
        /// Unique boundary string for request
        private var boundary: String = UUID().uuidString
        
        /**
         Class which represents body part
         */
        private class BodyPart {
            
            enum PartPosition {
                case initial
                case encapsulated
                case final
            }
            
            public var partPosition: PartPosition = .encapsulated
            
            private(set) var fileData:   Data
            private(set) var fileName:   String = "\(Int(Date().timeIntervalSince1970))"
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
            
            /**
             Method which write encoded body part to data
             */
            public func write(to data: inout Data, boundary: String) throws {
                
                if self.partPosition == .initial {
                    data.append(try self.boundaryStartString(boundary: boundary).asData())
                } else {
                    data.append(try self.boundaryEncapsulatedString(boundary: boundary).asData())
                }
                
                data.append(try self.contentDispositionString().asData())
                data.append(try self.contentTypeString().asData())
                data.append(try self.fileData.asData())
                data.append(try EncodingCharacters.crlf.asData())
                
                if self.partPosition == .final {
                    data.append(try self.boundaryEndString(boundary: boundary).asData())
                }
            }
        }
        
        /**
         
         Creates body part.
         
         ### Usage Example: ###
         ````
         { multipartFormData in
             multipartFormData.append(fileData: imageData, fieldName: "userAvatar", fileName: "avatar.jpeg", mimeType: "image/jpeg")
             multipartFormData.append(fileData: instructionsData, fieldName: "instructions", fileName: "instructions.pdf", mimeType: "application/pdf")
         }
         
         ````
         
         - Parameter fileData: File data which will be uploaded.
         - Parameter fieldName: Data field name.
         - Parameter fileName: Data file name.
         - Parameter mimeType: Data mime type.
         */
        public func append(fileData: Data, fieldName: String, fileName: String, mimeType: String) {
            self.bodyParts.append(.init(fileData: fileData, fieldName: fieldName, fileName: fileName, mimeType: mimeType))
        }
        
        /**
         Method which write encoded multipart form data to request
         */
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
}
