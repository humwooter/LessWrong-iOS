
import Foundation

class NetworkManager: ObservableObject {
    @Published var posts: [String: Post] = [:]
    @Published var selectedPost: Post?
    @Published var recentComments: [String: Comment] = [:]
    let lesswrongEndpoint = "https://www.lesswrong.com/graphql"
    @Published var currentEndpoint: String = "https://www.lesswrong.com/graphql"

    func fetchPosts(queryType: QueryType, searchText: String, username: String = "", limit: Int? = nil) async {
        print("QUERY TYPE: \(queryType)")
        print("USERNAME: \(username)")
        print("SEARCH TEXT: \(searchText)")
        let query: String
        print("RAW VALUE: \(queryType.rawValue)")
        switch queryType {
        case .topPosts, .newPosts:
            query = """
            query {
              posts(input: {terms: {view: "\(queryType.rawValue)", limit: \(limit ?? 10)}}) {
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
              comments(input: {terms: {view: "recentComments", limit: \(limit ?? 10)}}) {
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

        guard var urlComponents = URLComponents(string: currentEndpoint) else { return }
        urlComponents.queryItems = [URLQueryItem(name: "query", value: query)]
        guard let url = urlComponents.url else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .returnCacheDataElseLoad

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query], options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, queryType: queryType, searchText: searchText)
        } catch {
            print("Error making network request: \(error)")
        }
    }

    private func handleResponse(data: Data, queryType: QueryType, searchText: String) throws {
        switch queryType {
        case .comments:
            print("DECODING COMMENTS")
            let responseData = try JSONDecoder().decode(GraphQLResponse<CommentsData>.self, from: data)
            DispatchQueue.main.async {
                let filteredComments = responseData.data.comments.results.filter { comment in
                    searchText.isEmpty || comment.contents.lowercased().contains(searchText.lowercased()) || comment.user.slug.lowercased().contains(searchText.lowercased())
                }
                for comment in filteredComments {
                    self.recentComments[comment.pageUrl] = comment
                }
            }
        default:
            let responseData = try JSONDecoder().decode(GraphQLResponse<PostData>.self, from: data)
            DispatchQueue.main.async {
                let filteredPosts = responseData.data.posts.results.filter { post in
                    searchText.isEmpty || post.title.lowercased().contains(searchText.lowercased()) || post.user?.username.lowercased().contains(searchText.lowercased()) ?? false
                }
                for post in filteredPosts {
                    self.posts[post.url] = post
                }
            }
        }
    }

    func fetchPostDetail(url: String) async {
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

        guard var urlComponents = URLComponents(string: currentEndpoint) else { return }
        urlComponents.queryItems = [URLQueryItem(name: "query", value: query)]
        guard let url = urlComponents.url else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .returnCacheDataElseLoad

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query], options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let responseData = try JSONDecoder().decode(GraphQLResponse<PostDetailResponse>.self, from: data)
            DispatchQueue.main.async {
                let post = responseData.data.post.result
                self.selectedPost = post
                self.posts[post.url] = post
            }
        } catch {
            print("Error making network request: \(error)")
        }
    }

    func sortedPosts(by queryType: QueryType, searchText: String = "") -> [Post] {
        return posts.values.sorted { post1, post2 in
            let matchesSearchText1: Bool
            let matchesSearchText2: Bool

            if queryType == .userPosts {
                matchesSearchText1 = searchText.isEmpty || post1.author?.lowercased().contains(searchText.lowercased()) ?? (searchText.lowercased() == "unknown" || searchText.lowercased() == "anonymous")
                matchesSearchText2 = searchText.isEmpty || post2.author?.lowercased().contains(searchText.lowercased()) ?? (searchText.lowercased() == "unknown" || searchText.lowercased() == "anonymous")
            } else {
                matchesSearchText1 = searchText.isEmpty || post1.title.lowercased().contains(searchText.lowercased())
                matchesSearchText2 = searchText.isEmpty || post2.title.lowercased().contains(searchText.lowercased())
            }

            if matchesSearchText1 != matchesSearchText2 {
                return matchesSearchText1
            }

            switch queryType {
            case .newPosts:
                guard let date1 = post1.date, let date2 = post2.date else { return false }
                return date1 > date2
            case .userPosts:
                guard let voteCount1 = post1.voteCount, let voteCount2 = post2.voteCount else { return false }
                return voteCount1 > voteCount2
            default:
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
    
    struct UserInfo

: Decodable {
        let _id: String
        let slug: String
    }
}
