//
//  SearchModel.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/3/24.
//

import Foundation
import SwiftUI
import Combine

class SearchModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedQueryType: QueryType = .topPosts
    @Published var tokens: [FilterTokens] = []
}

enum FilterTokens: String, Identifiable, Hashable, CaseIterable {
    case topPosts, newPosts, userPosts, comments
    var id: Self { self }
}

enum QueryType: String, Identifiable, Hashable, CaseIterable {
    case topPosts = "top"
    case newPosts = "new"
    case userPosts = "user"
    case comments = "comments"
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .topPosts:
            return "top"
        case .newPosts:
            return "new"
        case .userPosts:
            return "user"
        case .comments:
            return "comment"
        }
    }
}
