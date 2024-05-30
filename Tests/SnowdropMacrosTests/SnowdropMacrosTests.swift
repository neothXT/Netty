//
//  SnowdropMacrosTests.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SnowdropMacros

final class SnowdropMacrosTests: XCTestCase {
    func testEndpointMacro() throws {
        assertMacroExpansion(
            """
            @Service
            protocol TestEndpoint {
                @GET(url: "/posts/{id=2}/comments")
                @Headers(["Content-Type": "application/json"])
                @Body("model")
                func getPosts(for id: Int, model: Model) async throws -> Post
            }
            """,
            expandedSource:
            """
            
            protocol TestEndpoint {
                func getPosts(for id: Int, model: Model) async throws -> Post
            }
            
            class TestEndpointService: TestEndpoint, Service {
                let baseUrl: URL
            
                var requestBlocks: [String: RequestHandler] = [:]
                var responseBlocks: [String: ResponseHandler] = [:]
            
                var decoder: JSONDecoder
                var pinningMode: PinningMode?
                var urlsExcludedFromPinning: [String]
            
                required init(
                    baseUrl: URL,
                    pinningMode: PinningMode? = nil,
                    urlsExcludedFromPinning: [String] = [],
                    decoder: JSONDecoder = .init()
                ) {
                    self.baseUrl = baseUrl
                    self.pinningMode = pinningMode
                    self.urlsExcludedFromPinning = urlsExcludedFromPinning
                    self.decoder = decoder
                }
            
                func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                    var key = "all"
                    if let path {
                        key = baseUrl.appending(path: path).absoluteString
                    }
                    requestBlocks[key] = block
                }
            
                func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                    var key = "all"
                    if let path {
                        key = baseUrl.appending(path: path).absoluteString
                    }
                    responseBlocks[key] = block
                }
            
                func getPosts(for id: Int = 2, model: Model) async throws -> Post {
                    let _queryItems: [QueryItem] = []
                    return try await getPosts(for: id, model: model, _queryItems: _queryItems)
                }

                func getPosts(for id: Int = 2, model: Model, _queryItems: [QueryItem]) async throws -> Post {
                    let url = baseUrl.appendingPathComponent("/posts/\\(id)/comments")
                    let rawUrl = baseUrl.appendingPathComponent("/posts/{id}/comments").absoluteString
                    let headers: [String: Any] = ["Content-Type": "application/json"]
            
                    var request = prepareBasicRequest(url: url, method: "GET", queryItems: _queryItems, headers: headers)
                    var data: Data?
            
                    if let header = headers["Content-Type"] as? String, header == "application/x-www-form-urlencoded" {
                        data = Snowdrop.core.prepareUrlEncodedBody(data: model)
                    } else if let header = headers["Content-Type"] as? String, header == "application/json" {
                        data = Snowdrop.core.prepareBody(data: model)
                    }
            
                    request.httpBody = data
            
                    return try await Snowdrop.core.performRequestAndDecode(
                        request,
                        rawUrl: rawUrl,
                        decoder: decoder,
                        pinning: pinningMode,
                        urlsExcludedFromPinning: urlsExcludedFromPinning,
                        requestBlocks: requestBlocks,
                        responseBlocks: responseBlocks
                    )
                }
            
                private func prepareBasicRequest(url: URL, method: String, queryItems: [QueryItem], headers: [String: Any]) -> URLRequest {
                    var finalUrl = url

                    if !queryItems.isEmpty {
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                        components.queryItems = queryItems.map {
                            $0.toUrlQueryItem()
                        }
                        finalUrl = components.url!
                    }

                    var request = URLRequest(url: finalUrl)
                    request.httpMethod = method

                    headers.forEach { key, value in
                        request.addValue("\\(value)", forHTTPHeaderField: key)
                    }

                    return request
                }
            }
            """,
            macros: [
                "Service": ServiceMacro.self,
                "GET": GetMacro.self,
                "Headers": HeadersMacro.self,
                "Body": BodyMacro.self
            ]
        )
    }
    
    func testUploadMacro() throws {
        assertMacroExpansion(
            """
            @Service
            public protocol TestEndpoint {
                @POST(url: "/file")
                @FileUpload
                @Body("file")
                func uploadFile(file: UIImage) async throws -> Post
            }
            """,
            expandedSource:
            """
            
            public protocol TestEndpoint {
                func uploadFile(file: UIImage) async throws -> Post
            }
            
            public class TestEndpointService: TestEndpoint, Service {
                public let baseUrl: URL
            
                public var requestBlocks: [String: RequestHandler] = [:]
                public var responseBlocks: [String: ResponseHandler] = [:]
            
                public var decoder: JSONDecoder
                public var pinningMode: PinningMode?
                public var urlsExcludedFromPinning: [String]
            
                public required init(
                    baseUrl: URL,
                    pinningMode: PinningMode? = nil,
                    urlsExcludedFromPinning: [String] = [],
                    decoder: JSONDecoder = .init()
                ) {
                    self.baseUrl = baseUrl
                    self.pinningMode = pinningMode
                    self.urlsExcludedFromPinning = urlsExcludedFromPinning
                    self.decoder = decoder
                }
            
                public func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                    var key = "all"
                    if let path {
                        key = baseUrl.appending(path: path).absoluteString
                    }
                    requestBlocks[key] = block
                }
            
                public func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                    var key = "all"
                    if let path {
                        key = baseUrl.appending(path: path).absoluteString
                    }
                    responseBlocks[key] = block
                }
            
                public func uploadFile(file: UIImage) async throws -> Post {
                    let _queryItems: [QueryItem] = []
                    let _payloadDescription: PayloadDescription? = PayloadDescription(name: "payload",
                                                                                      fileName: "payload",
                                                                                      mimeType: MimeType(from: fileData).rawValue)
                    return try await uploadFile(file: file, _payloadDescription: _payloadDescription, _queryItems: _queryItems)
                }
            
                public func uploadFile(file: UIImage, _payloadDescription: PayloadDescription?, _queryItems: [QueryItem]) async throws -> Post {
                    let url = baseUrl.appendingPathComponent("/file")
                    let rawUrl = baseUrl.appendingPathComponent("/file").absoluteString
                    let headers: [String: Any] = [:]
            
                    var request = prepareBasicRequest(url: url, method: "POST", queryItems: _queryItems, headers: headers)

                    if (headers["Content-Type"] as? String) == nil {
                        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
                    }
            
                    request.httpBody = Snowdrop.core.dataWithBoundary(file, payloadDescription: _payloadDescription)
            
                    return try await Snowdrop.core.performRequestAndDecode(
                        request,
                        rawUrl: rawUrl,
                        decoder: decoder,
                        pinning: pinningMode,
                        urlsExcludedFromPinning: urlsExcludedFromPinning,
                        requestBlocks: requestBlocks,
                        responseBlocks: responseBlocks
                    )
                }
            
                private func prepareBasicRequest(url: URL, method: String, queryItems: [QueryItem], headers: [String: Any]) -> URLRequest {
                    var finalUrl = url

                    if !queryItems.isEmpty {
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                        components.queryItems = queryItems.map {
                            $0.toUrlQueryItem()
                        }
                        finalUrl = components.url!
                    }

                    var request = URLRequest(url: finalUrl)
                    request.httpMethod = method

                    headers.forEach { key, value in
                        request.addValue("\\(value)", forHTTPHeaderField: key)
                    }

                    return request
                }
            }
            """,
            macros: [
                "Service": ServiceMacro.self,
                "POST": GetMacro.self,
                "Body": BodyMacro.self,
                "FileUpload": FileUploadMacro.self
            ]
        )
    }
    
    func testMockableMacro() throws {
        assertMacroExpansion(
            """
            @Mockable
            public protocol TestEndpoint {
                @POST(url: "/file")
                @FileUpload
                @Body("file")
                func uploadFile(file: UIImage) async throws -> Post
            }
            """,
            expandedSource:
            """
            
            public protocol TestEndpoint {
                func uploadFile(file: UIImage) async throws -> Post
            }
            
            public class TestEndpointServiceMock: TestEndpoint, Service {
                public let baseUrl: URL
            
                public var requestBlocks: [String: RequestHandler] = [:]
                public var responseBlocks: [String: ResponseHandler] = [:]
            
                public var decoder: JSONDecoder
                public var pinningMode: PinningMode?
                public var urlsExcludedFromPinning: [String]
            
                public required init(
                    baseUrl: URL,
                    pinningMode: PinningMode? = nil,
                    urlsExcludedFromPinning: [String] = [],
                    decoder: JSONDecoder = .init()
                ) {
                    self.baseUrl = baseUrl
                    self.pinningMode = pinningMode
                    self.urlsExcludedFromPinning = urlsExcludedFromPinning
                    self.decoder = decoder
                }
            
                public func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                    var key = "all"
                    if let path {
                        key = baseUrl.appending(path: path).absoluteString
                    }
                    requestBlocks[key] = block
                }
            
                public func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                    var key = "all"
                    if let path {
                        key = baseUrl.appending(path: path).absoluteString
                    }
                    responseBlocks[key] = block
                }
            
                public var uploadFileResult: Result<Post, Error> = .failure(SnowdropError(type: .unknown))
            
                public func uploadFile(file: UIImage) async throws -> Post {
                    let _queryItems: [QueryItem] = []
                    let _payloadDescription: PayloadDescription? = PayloadDescription(name: "payload",
                                                                                      fileName: "payload",
                                                                                      mimeType: MimeType(from: fileData).rawValue)
                    return try await uploadFile(file: file, _payloadDescription: _payloadDescription, _queryItems: _queryItems)
                }
            
                public func uploadFile(file: UIImage, _payloadDescription: PayloadDescription?, _queryItems: [QueryItem]) async throws -> Post {
                    try uploadFileResult.get()
                }
            
                private func prepareBasicRequest(url: URL, method: String, queryItems: [QueryItem], headers: [String: Any]) -> URLRequest {
                    var finalUrl = url

                    if !queryItems.isEmpty {
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                        components.queryItems = queryItems.map {
                            $0.toUrlQueryItem()
                        }
                        finalUrl = components.url!
                    }

                    var request = URLRequest(url: finalUrl)
                    request.httpMethod = method

                    headers.forEach { key, value in
                        request.addValue("\\(value)", forHTTPHeaderField: key)
                    }

                    return request
                }
            }
            """,
            macros: [
                "Mockable": MockableMacro.self,
                "POST": GetMacro.self,
                "Body": BodyMacro.self,
                "FileUpload": FileUploadMacro.self
            ]
        )
    }
}
