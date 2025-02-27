//
//  SnowdropTests.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import XCTest
@testable import Snowdrop
import AppKit

final class SnowdropTests: XCTestCase {
    private let baseUrl = URL(string: "https://jsonplaceholder.typicode.com")!
    private lazy var service = TestEndpointServiceImpl(baseUrl: baseUrl, verbose: true)
    private lazy var mock = TestEndpointServiceMock(baseUrl: baseUrl)

    func testGetTask() async throws {
        let result = try await service.getPost(id: 2)
        XCTAssertTrue(result.id == 2)
    }
    
    func testGetTaskWithNullableParam() async throws {
        let expectation = expectation(description: "Should not add 'nil' to path")
        service.addBeforeSendingBlock { request in
            if request.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/" {
                expectation.fulfill()
            }
            return request
        }
        
        _ = try? await service.getNullablePost(id: nil)
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testPostTask() async throws {
        let result = try await service.addPost(model: .init(id: 101, userId: 1, title: "Some title", body: "some body"))
        XCTAssertTrue(result.title == "Some title")
    }
    
    func testQueryItems() async throws {
        let expectation = expectation(description: "Should contain queryItems")
        service.addBeforeSendingBlock { request in
            if request.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/12?test=true" {
                expectation.fulfill()
            }
            return request
        }
        _ = try await service.getPost(id: 12, _queryItems: [.init(key: "test", value: true)])
        
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testQuertItemsMacro() async throws {
        let expectation = expectation(description: "Should contain queryItems")
        service.addBeforeSendingBlock { request in
            if request.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/12?boolVal=true&intVal=5&stringVal=five" {
                expectation.fulfill()
            }
            return request
        }
        _ = try await service.getPostWithQueryItem(id: 12, boolVal: true, intVal: 5, stringVal: "five")
        
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testInterception() async throws {
        let expectation = expectation(description: "Should intercept request")
        service.addBeforeSendingBlock { request in
            if request.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/7/comments" {
                expectation.fulfill()
            }
            return request
        }
        _ = try await service.getComments(id: 7)
        
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testOnResponse() async throws {
        let expectation = expectation(description: "Should intercept response")
        service.addOnResponseBlock(for: "posts/.{1,}/comments") { data, urlResponse in
            if urlResponse.statusCode == 200 && urlResponse.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/9/comments" {
                expectation.fulfill()
            }
            return data
        }
        _ = try await service.getComments(id: 9)
        
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testNon200StatusCode() async throws {
        do {
            _ = try await service.getCertainComment(id: 9, commentId: 1)
        } catch {
            let snowdropError = try XCTUnwrap(error as? SnowdropError)
            XCTAssertTrue(snowdropError.type == .unexpectedResponse)
            XCTAssertEqual(snowdropError.details?.statusCode, 404)
            XCTAssertEqual(snowdropError.details?.localizedString, HTTPURLResponse.localizedString(forStatusCode: 404).capitalized)
        }
    }
    
    func testNonThrowingPosts() async throws {
        let result = await service.getNonThrowingPosts()
        XCTAssertNotNil(result)
    }
    
    func testPositiveGetTaskMock() async throws {
        let post = Post(id: 1, userId: 1, title: "Mock title", body: "Mock body")
        mock.getPostResult = .success(post)
        let result = try await mock.getPost(id: 5)
        XCTAssertTrue(post.title == result.title)
    }
    
    func testNegativeGetTaskMock() async throws {
        mock.getPostResult = .failure(SnowdropError(type: .unexpectedResponse))
        do {
            _ = try await mock.getPost(id: 4)
        } catch {
            let snowdropError = try XCTUnwrap(error as? SnowdropError)
            XCTAssertTrue(snowdropError.type == .unexpectedResponse)
        }
    }
    
    func testNonReturnableThrowableMock() async throws {
        mock.getNoResponsePostsResult = SnowdropError(type: .failedToMapResponse)
        do {
            _ = try await mock.getNoResponsePosts()
        } catch {
            let snowdropError = try XCTUnwrap(error as? SnowdropError)
            XCTAssertTrue(snowdropError.type == .failedToMapResponse)
        }
    }
    
    func testFileUpload() async throws {
        let expectation = expectation(description: "Request body should contain payload description")
        guard let imageData = NSData(contentsOf: URL(string: "https://github.com/neothXT/Snowdrop/blob/main/Snowdrop_Logo.png?raw=true")!)?.base64EncodedData() else {
            throw SnowdropError(type: .unknown)
        }
        
        service.addBeforeSendingBlock { request in
            guard let bodyString = String(data: request.httpBody!, encoding: .utf8) else { return request }
            
            if bodyString.contains("Content-Disposition: form-data; name=") {
                expectation.fulfill()
            }
            
            return request
        }
        
        _ = try? await service.uploadFile(body: imageData)
        await fulfillment(of: [expectation], timeout: 5)
    }
}
