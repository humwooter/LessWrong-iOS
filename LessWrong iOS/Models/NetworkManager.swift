import Foundation

class NetworkManager: ObservableObject {
    @Published var posts: [String: Post] = [:]
    @Published var selectedPost: Post?
    @Published var recentComments: [String: Comment] = [:]
    let lesswrong_endpoint =  "https://www.lesswrong.com/graphql"

    
    
    
//    func fetchPostsAsync(queryType: QueryType, searchText: String, username: String = "", limit: Int? = nil, completion: @escaping ([Post]) -> Void) {
//        let query: String
//        switch queryType {
//        case .topPosts:
//            query = """
//            query {
//              posts(input: {terms: {view: "top", limit: \(limit ?? 10)}}) {
//                results {
//                  _id
//                  url: pageUrl
//                  title
//                  author
//                  date: postedAt
//                  voteCount
//                  commentCount
//                  tags {
//                    _id
//                    name
//                  }
//                  meta
//                }
//              }
//            }
//            """
//        case .newPosts:
//            query = """
//            query {
//              posts(input: {terms: {view: "new", limit: \(limit ?? 10)}}) {
//                results {
//                  _id
//                  url: pageUrl
//                  title
//                  author
//                  date: postedAt
//                  voteCount
//                  commentCount
//                  tags {
//                    _id
//                    name
//                  }
//                  meta
//                }
//              }
//            }
//            """
//        case .userPosts:
//            query = """
//            query {
//              posts(input: {terms: {author: "\(username)", limit: \(limit ?? 10)}}) {
//                results {
//                  _id
//                  url: pageUrl
//                  title
//                  author
//                  date: postedAt
//                  voteCount
//                  commentCount
//                  tags {
//                    _id
//                    name
//                  }
//                  meta
//                }
//              }
//            }
//            """
//        case .comments:
//            query = """
//            query {
//              posts(input: {terms: {view: "comment", limit: \(limit ?? 10)}}) {
//                results {
//                  _id
//                  url: pageUrl
//                  title
//                  author
//                  date: postedAt
//                  voteCount
//                  commentCount
//                  tags {
//                    _id
//                    name
//                  }
//                  meta
//                }
//              }
//            }
//            """
//        }
//
//        guard let url = URL(string: lesswrong_endpoint) else { return }
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
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error making network request: \(error)")
//                return
//            }
//
//            guard let data = data else {
//                print("No data received")
//                return
//            }
//
//            do {
//                let responseData = try JSONDecoder().decode(GraphQLResponse<PostData>.self, from: data)
//                DispatchQueue.main.async {
//                    completion(responseData.data.posts.results)
//                }
//            } catch {
//                print("Error decoding response: \(error)")
//            }
//        }.resume()
//    }
//    
    func fetchPosts(queryType: QueryType, searchText: String, username: String = "", limit: Int? = nil) {
        print("QUERY TYPE: \(queryType)")
        print("USERNAME: \(username)")
        print("SEARCH TEXT: \(searchText)")
        let query: String
        print("RAW VALUE: \(queryType.rawValue)")
        switch queryType {
        case .topPosts, .newPosts, .userPosts:
            query = """
            query {
              posts(input: {terms: {view: "\(queryType.rawValue)", limit: \(limit ?? 10), author: "\(username)"}}) {
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
        case .comments:
            query = """
            query {
                                 comments(input: {
                   terms: {
                     view: "recentComments"
                                          limit: \(limit ?? 10)
                   }
                 }) {
                   results {
                     _id
                     post {
                       _id
                       title
                       slug
                     }
                     user {
                       _id
                       slug
                     }
                     postId
                     pageUrl
                     contents:htmlBody
                   }
                 }
                              
                 }
            """
        }

        guard let url = URL(string: lesswrong_endpoint) else { return }

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

                do {
                    let responseData = try JSONDecoder().decode(GraphQLResponse<PostData>.self, from: data)
                    DispatchQueue.main.async {
                        let filtered_posts =  responseData.data.posts.results.filter { post in
                            
                            searchText.isEmpty || post.title.lowercased().contains(searchText.lowercased()) || ((post.user?.username.lowercased().contains(searchText.lowercased())) != nil)

                        }
                        for post in filtered_posts {
                                self.posts[post.url] = post
                            }
                    }
                } catch {
                    print("Error decoding response: \(error)")
                }
            }.resume()
        }
    }
    
//    func fetchPosts(queryType: QueryType, searchText: String, username: String = "", limit: Int? = nil) {
//        print("QUERY TYPE: \(queryType)")
//        print("USERNAME: \(username)")
//        print("SEARCH TEXT: \(searchText)")
//        let query: String
//        switch queryType {
//        case .topPosts:
//            query = """
//            query {
//              posts(input: {terms: {view: "top", limit: \(limit ?? 10)}}) {
//                results {
//                  _id
//                  url: pageUrl
//                  title
//                  author
//                  date: postedAt
//                  voteCount
//                  commentCount
//                  tags {
//                    _id
//                    name
//                  }
//                  meta
//                }
//              }
//            }
//            """
//        case .newPosts:
//            query = """
//            query {
//              posts(input: {terms: {view: "new", limit: \(limit ?? 10)}}) {
//                results {
//                  _id
//                  url: pageUrl
//                  title
//                  author
//                  date: postedAt
//                  voteCount
//                  commentCount
//                  tags {
//                    _id
//                    name
//                  }
//                  meta
//                }
//              }
//            }
//            """
//        case .userPosts:
//                   query = """
//                   query {
//                     posts(input: {terms: {view: "top", limit: \(limit ?? 10), authorName: "\(username)"}}) {
//                       results {
//                         _id
//                         url: pageUrl
//                         title
//                         author
//                         date: postedAt
//                         voteCount
//                         commentCount
//                         tags {
//                           _id
//                           name
//                         }
//                         meta
//                       }
//                     }
//                   }
//                   """
//        case .comments:
//            query = """
//            query {
//                                 comments(input: {
//                   terms: {
//                     view: "recentComments"
//                                          limit: \(limit ?? 10)
//                   }
//                 }) {
//                   results {
//                     _id
//                     post {
//                       _id
//                       title
//                       slug
//                     }
//                     user {
//                       _id
//                       slug
//                     }
//                     postId
//                     pageUrl
//                     contents:htmlBody
//                   }
//                 }
//                              
//                 }
//            """
//        }
//
//        guard let url = URL(string: lesswrong_endpoint) else { return }
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
//
//                              switch queryType {
//
//                              case .comments:
//
//                                  let responseData = try JSONDecoder().decode(GraphQLResponse<CommentsData>.self, from: data)
//
//                                  DispatchQueue.main.async {
//
//                                      self.recentComments = responseData.data.comments.results
//
//                                  }
//
//                              default:
//
//                                  let responseData = try JSONDecoder().decode(GraphQLResponse<PostData>.self, from: data)
//
//                                  DispatchQueue.main.async {
//
//                                      self.posts = responseData.data.posts.results.filter { post in
//
//                                          searchText.isEmpty || post.title.lowercased().contains(searchText.lowercased()) || ((post.user?.username.lowercased().contains(searchText.lowercased())) != nil)
//
//                                      }
//
//                                  }
//
//                              }
//
//                          } catch {
//
//                              print("Error decoding response: \(error)")
//
//                          }
//
//                      }.resume()
//        }
//    }
    
    
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

         guard let url = URL(string: lesswrong_endpoint) else { return }

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

                 do {
                     let responseData = try JSONDecoder().decode(GraphQLResponse<PostDetailResponse>.self, from: data)
                     DispatchQueue.main.async {
                         let post = responseData.data.post.result
                             self.selectedPost = post
                             self.posts[post.url] = post
                     }
                 } catch {
                     print("Error decoding response: \(error)")
                 }
             }.resume()
         }
     }
    
    func sortedPosts(by queryType: QueryType, searchText: String = "") -> [Post] {
        // Sort posts based on the presence of search text and other criteria
        return posts.values.sorted { post1, post2 in
            // Define match conditions based on query type
            let matchesSearchText1: Bool
            let matchesSearchText2: Bool

            if queryType == .userPosts {
                matchesSearchText1 = searchText.isEmpty || (post1.author?.lowercased().contains(searchText.lowercased()) ?? (searchText.lowercased() == "unknown" || searchText.lowercased() == "anonymous"))
                matchesSearchText2 = searchText.isEmpty || (post2.author?.lowercased().contains(searchText.lowercased()) ?? (searchText.lowercased() == "unknown" || searchText.lowercased() == "anonymous"))
            } else {
                matchesSearchText1 = searchText.isEmpty || post1.title.lowercased().contains(searchText.lowercased())
                matchesSearchText2 = searchText.isEmpty || post2.title.lowercased().contains(searchText.lowercased())
            }

            // Prioritize posts that match the search text
            if matchesSearchText1 != matchesSearchText2 {
                return matchesSearchText1
            }

            // If both or neither match the search text, sort based on the query type
            switch queryType {
            case .newPosts:
                // Sort by date for new posts
                guard let date1 = post1.date, let date2 = post2.date else { return false }
                return date1 > date2
            case .userPosts:
                // Sort by vote count for user posts
                guard let voteCount1 = post1.voteCount, let voteCount2 = post2.voteCount else { return false }
                return voteCount1 > voteCount2
            default:
                // Sort by vote count for other types
                guard let voteCount1 = post1.voteCount, let voteCount2 = post2.voteCount else { return false }
                return voteCount1 > voteCount2
            }
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


struct CommentsData: Decodable {
    let comments: CommentResults
}

struct CommentResults: Decodable {
    let results: [Comment]
}

struct Comment: Decodable, Identifiable {

    let _id: String
        
    let post: PostInfo
    
    let contents: String
    

    let user: UserInfo

    let postId: String

    let pageUrl: String

    

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
