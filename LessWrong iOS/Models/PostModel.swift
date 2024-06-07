//
//  PostModel.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/6/24.
//

import Foundation
import SwiftUI

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T
}

struct PostData: Decodable {
    let posts: PostResults
}

struct PostResults: Decodable {
    let results: [Post]
}

struct PostDetailResponse: Decodable {
    let post: PostDetail
}

struct PostDetail: Decodable {
    let result: Post
}

struct Post: Identifiable, Decodable {
    var id: String { _id }
    let _id: String
    let url: String
    let title: String
    let slug: String?
    let author: String?
    let date: String?
    let voteCount: Int?
    let commentCount: Int?
    let tags: [Tag]?
    let meta: Bool?
    let baseScore: Int?
    let question: Bool?
    let user: User?
    
    struct Tag: Decodable {
        let _id: String
        let name: String
    }
    
    struct User: Decodable {
        let username: String
        let slug: String
        let karma: Int
        let maxPostCount: Int
        let commentCount: Int
    }
}

struct CommentsData: Decodable {
    let comments: CommentResults
}

struct CommentResults: Decodable {
    let results: [Comment]
}

struct Comment: Decodable, Identifiable {
    let _id: String
    let post: PostInfo
    let user: UserInfo
    let postId: String
    let pageUrl: String
    let contents: String
    let voteCount: Int?
    
    var id: String { _id }
    
    struct PostInfo: Decodable {
        let _id: String
        let title: String
        let slug: String
    }
    
    struct UserInfo: Decodable {
        let _id: String
        let slug: String
    }
}
