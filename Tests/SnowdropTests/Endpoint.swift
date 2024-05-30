//
//  Endpoint.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation
import Combine
import Snowdrop

public struct Post: Codable {
    let id, userId: Int
    let title, body: String
}

public struct Comment: Codable {
    let postId, id: Int
    let name, email, body: String
}

@Service
@Mockable
public protocol TestEndpoint {
    @GET(url: "/posts/{id=2}")
    func getPost(id: Int) async throws -> Post
    
    @GET(url: "/posts/{id=4}/comments")
    func getComments(id: Int) async throws -> [Comment]
    
    @GET(url: "/posts/{id=4}/comments/{commentId=2}")
    func getCertainComment(id: Int, commentId: Int) async throws -> [Comment]
    
    @POST(url: "/posts")
    @Headers([
        "Content-Type": "application/json",
    ])
    @Body("model")
    func addPost(model: Post) async throws -> Post
    
    @GET(url: "/posts/")
    func getNonThrowingPosts() async -> [Post]?
    
    @GET(url: "posts")
    func getNoResponsePosts() async throws
}

class MyRepository {
  private let baseURL = URL(string: "https://my-url.com/api/")!
  let service: TestEndpoint & Service

  init() {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    service = TestEndpointService(baseUrl: baseURL)
  }
}
