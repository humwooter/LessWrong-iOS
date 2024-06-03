//
//  NetworkManager.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/3/24.
//
//import Foundation
//
//class NetworkManager: ObservableObject {
//    @Published var posts: [Post] = []
//    @Published var selectedPost: Post?
//
//    func fetchPosts() {
//        let query = """
//        query {
//          posts(input: {terms: {view: "top"}}) {
//            results {
//              url: pageUrl
//              title
//              author
//              date: postedAt
//              voteCount
//              commentCount
//            }
//          }
//        }
//        """
//        
//        guard let url = URL(string: "https://www.lesswrong.com/graphql") else { return }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let body: [String: Any] = ["query": query]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
//        } catch {
//            print("Error serializing JSON: \(error)")
//            return
//        }
//        
//        DispatchQueue.global(qos: .background).async {
//            URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    print("Error making network request: \(error)")
//                    return
//                }
//                
//                guard let data = data else {
//                    print("No data received")
//                    return
//                }
//                
//                if let responseString = String(data: data, encoding: .utf8) {
//                    print("Response Data: \(responseString)")
//                }
//                
//                do {
//                    let responseData = try JSONDecoder().decode(GraphQLResponse<PostData>.self, from: data)
//                    DispatchQueue.main.async {
//                        self.posts = responseData.data.posts.results
//                    }
//                } catch {
//                    print("Error decoding response: \(error)")
//                }
//            }.resume()
//        }
//    }
//
//    func fetchPostDetail(url: String) {
//        let query = """
//        query {
//          post(url: "\(url)") {
//            url: pageUrl
//            title
//            author
//            date: postedAt
//            voteCount
//            commentCount
//          }
//        }
//        """
//        
//        guard let url = URL(string: "https://www.lesswrong.com/graphql") else { return }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let body: [String: Any] = ["query": query]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
//        } catch {
//            print("Error serializing JSON: \(error)")
//            return
//        }
//        
//        DispatchQueue.global(qos: .background).async {
//            URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    print("Error making network request: \(error)")
//                    return
//                }
//                
//                guard let data = data else {
//                    print("No data received")
//                    return
//                }
//                
//                if let responseString = String(data: data, encoding: .utf8) {
//                    print("Response Data: \(responseString)")
//                }
//                
//                do {
//                    let responseData = try JSONDecoder().decode(GraphQLResponse<PostDetailData>.self, from: data)
//                    DispatchQueue.main.async {
//                        self.selectedPost = responseData.data.post
//                    }
//                } catch {
//                    print("Error decoding response: \(error)")
//                }
//            }.resume()
//        }
//    }
//}
//
//struct GraphQLResponse<T: Decodable>: Decodable {
//    let data: T
//}
//
//struct PostData: Decodable {
//    let posts: PostResults
//}
//
//struct PostResults: Decodable {
//    let results: [Post]
//}
//
//struct PostDetailData: Decodable {
//    let post: Post
//}
//
//struct Post: Identifiable, Decodable {
//    var id: String { url }
//    let url: String
//    let title: String
//    let author: String?
//    let date: String
//    let voteCount: Int
//    let commentCount: Int
//}
//
import Foundation

class NetworkManager: ObservableObject {
    @Published var posts: [Post] = []
    @Published var selectedPost: Post?

    func fetchPosts(queryType: QueryType, searchText: String, username: String = "", limit: Int? = nil) {
        let query: String
        switch queryType {
        case .topPosts:
            query = """
            query {
              posts(input: {terms: {view: "top", limit: \(limit ?? 10)}}) {
                results {
                  _id
                  url: pageUrl
                  title
                  author
                  date: postedAt
                  voteCount
                  commentCount
                  tags {
                    _id
                    name
                  }
                  meta
                }
              }
            }
            """
        case .newPosts:
            query = """
            query {
              posts(input: {terms: {view: "new", limit: \(limit ?? 10)}}) {
                results {
                  _id
                  url: pageUrl
                  title
                  author
                  date: postedAt
                  voteCount
                  commentCount
                  tags {
                    _id
                    name
                  }
                  meta
                }
              }
            }
            """
        case .userPosts:
                   query = """
                   query {
                     posts(input: {terms: {author: "\(username)", limit: \(limit ?? 10)}}) {
                       results {
                         _id
                         url: pageUrl
                         title
                         author
                         date: postedAt
                         voteCount
                         commentCount
                         tags {
                           _id
                           name
                         }
                         meta
                       }
                     }
                   }
                   """
        }

        guard let url = URL(string: "https://www.lesswrong.com/graphql") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["query": query]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error making network request: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response Data: \(responseString)")
                }
                
                do {
                    let responseData = try JSONDecoder().decode(GraphQLResponse<PostData>.self, from: data)
                    DispatchQueue.main.async {
                        self.posts = responseData.data.posts.results.filter { post in
                            searchText.isEmpty || post.title.lowercased().contains(searchText.lowercased()) || ((post.user?.username.lowercased().contains(searchText.lowercased())) != nil)
                        }
                    }
                } catch {
                    print("Error decoding response: \(error)")
                }
            }.resume()
        }
    }

    func fetchPostDetail(url: String) {
        let query = """
        query {
            post(input: {selector: {url: "\(url)"}}) {
                result {
                    _id
                    title
                    slug
                    pageUrl
                    postedAt
                    baseScore
                    voteCount
                    commentCount
                    meta
                    question
                    url
                    user {
                        username
                        slug
                        karma
                        maxPostCount
                        commentCount
                    }
                }
            }
        }
        """
        
        guard let url = URL(string: "https://www.lesswrong.com/graphql") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["query": query]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error making network request: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response Data: \(responseString)")
                }
                
                do {
                    let responseData = try JSONDecoder().decode(GraphQLResponse<PostDetailResponse>.self, from: data)
                    DispatchQueue.main.async {
                        self.selectedPost = responseData.data.post.result
                    }
                } catch {
                    print("Error decoding response: \(error)")
                }
            }.resume()
        }
    }
}

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

