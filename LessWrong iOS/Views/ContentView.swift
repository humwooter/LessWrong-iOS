//
//  ContentView.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/2/24.
//

import SwiftUI
import CoreData
import WebKit
import UIKit



struct ContentView: View {
    var body : some View {
        MainView()
    }
}

struct MainView: View {
    @StateObject var networkManager = NetworkManager()
    @ObservedObject var searchModel = SearchModel()
    
    var body : some View {
        MainChildView()
            .accentColor(.red)
            .environmentObject(networkManager)
            .environmentObject(searchModel)
            .searchable(text: $searchModel.searchText, tokens: $searchModel.tokens) { token in
                switch token {
                case .newPosts:
                    Text("New Posts")
                case .topPosts:
                    Text("Top Posts")
                case .userPosts:
                    Text("User")
                case .comments:
                    Text("Comment")
                }
            }
    }
}

struct MainChildView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedQueryType: QueryType = .topPosts
    @State private var postLimit: String = "70"
    @State private var username: String = "User"
    @EnvironmentObject var searchModel: SearchModel
    @Environment(\.customFont) var customFont: Font
    @Environment(\.isSearching) private var isSearching
    
    
    @State private var showingShareSheet = false
    @State private var selectedURL = ""
    
    private var shouldPresentShareSheet: Binding<Bool> {
        Binding(
            get: { !selectedURL.isEmpty && showingShareSheet },
            set: { showingShareSheet = $0 }
        )
    }



    
    var body: some View {
        NavigationView {
            mainView()
                .background {
                    ZStack {
                        LinearGradient(colors: [getTopBackgroundColor(),getBackgroundColor()], startPoint: .top, endPoint: .bottom)
                    }.ignoresSafeArea(.all)
                }
                .scrollContentBackground(.hidden)
            .navigationTitle("Posts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolBarMenu()
                }
            }
            .onAppear {
                          if let limit = Int(postLimit) {
                              networkManager.fetchPosts(queryType: selectedQueryType, searchText: searchModel.searchText, username: username, limit: limit)
                          }
    
                      }
            
            
        }
    }
    
    
    func getTopBackgroundColor() -> Color {
        if colorScheme == .light {
            return Color("Background Color Light Light")
        } else {
            return .clear
        }
    }
    
    func getBackgroundColor() -> Color {
        if colorScheme == .dark {
            return .brown.opacity(0.2)
        } else {
            return Color("Background Color Light Dark")
        }
    }

    func getColor() -> Color {
        if colorScheme == .dark {
            return .white
        } else {
            return .black
        }
    }
    
    func getSectionColor() -> Color {
        if colorScheme == .light {
            return .white
        } else {
            return .white.opacity(0.2)
        }
    }
    
    
   
    
    @ViewBuilder
    func toolBarMenu() -> some View {
        Menu {
            Picker("Query Type", selection: $selectedQueryType) {
                Text("Top Posts").tag(QueryType.topPosts)
                Text("New Posts").tag(QueryType.newPosts)
            }
            .onChange(of: selectedQueryType) { _ in
                fetchPostsIfNeeded()
            }
            .onChange(of: searchModel.searchText) { oldValue, newValue in
                fetchPostsIfNeeded()
            }

            if case .userPosts = selectedQueryType {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: username) { _ in
                        fetchPostsIfNeeded()
                    }
            }

            TextField("Post Limit", text: $postLimit)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: postLimit) { _ in
                    fetchPostsIfNeeded()
                }
        } label: {
            Label("Options", systemImage: "slider.horizontal.3")
        }
    }

    private func fetchPostsIfNeeded() {
        if let limit = Int(postLimit) {
            networkManager.fetchPosts(queryType: selectedQueryType, searchText: searchModel.searchText, username: searchModel.searchText, limit: limit)
        }
    }
    
    @ViewBuilder
    func mainView() -> some View {
        if !isSearching {
//            ScrollView {
                List {
                    ForEach(networkManager.sortedPosts(by: selectedQueryType, searchText: username), id: \.id) { post in
                        Section {
                            postFrontView(post: post)
                                .swipeActions(edge: .trailing) {
                                                Button {
                                                    selectedURL = post.url
                                                    // Pseudocode for sharing the post
                                                    showingShareSheet = true
                                                } label: {
                                                    Label("Share", systemImage: "square.and.arrow.up")
                                                }
                                                .tint(.cyan)
                                               
                                            }
                                            .swipeActions(edge: .leading) {
                                                Button {
                                                    // Pseudocode for bookmarking the post
                                                    // This should eventually add the post URL to a persisted collection
                                                    // Example: networkManager.bookmarkPost(post.url)
                                                } label: {
                                                    Label("Bookmark", systemImage: "bookmark.fill")
                                                }
                                                .tint(.red)
                                            }
                                     
                               
                        }
                        .sheet(isPresented: shouldPresentShareSheet) {
                                ShareSheet(items: [URL(string: selectedURL) as Any])
                                    .presentationDetents([.medium]) // Show bottom half of the screen
                        }
                        .listSectionSpacing(10)
                        .listRowBackground(getSectionColor().opacity(0.5))
                    }
                    
                }
                .setNavigationBarTitleToLightMode()
                
//            }
        } else {
            
                if searchModel.tokens.isEmpty && searchModel.searchText.isEmpty { //present possible tokens
                    List {
                        suggestedSearchView()
                    }
                }
            else {
                
                
                    List {
                        if selectedQueryType != .comments {
                            ForEach(networkManager.sortedPosts(by: selectedQueryType, searchText: searchModel.searchText), id: \.id) { post in
                                Section {
                                    postFrontView(post: post)
                                        .swipeActions(edge: .trailing) {
                                                        Button {
                                                            selectedURL = post.url
                                                            // Pseudocode for sharing the post
                                                            showingShareSheet = true
                                                        } label: {
                                                            Label("Share", systemImage: "square.and.arrow.up")
                                                        }
                                                        .tint(.cyan)
                                                       
                                                    }
                                                    .swipeActions(edge: .leading) {
                                                        Button {
                                                            // Pseudocode for bookmarking the post
                                                            // This should eventually add the post URL to a persisted collection
                                                            // Example: networkManager.bookmarkPost(post.url)
                                                        } label: {
                                                            Label("Bookmark", systemImage: "bookmark.fill")
                                                        }
                                                        .tint(.red)
                                                    }
                                             
                                       
                                }
                                .sheet(isPresented: $showingShareSheet) {
                                    if !selectedURL.isEmpty {
                                        ShareSheet(items: [URL(string: selectedURL) as Any])
                                            .presentationDetents([.medium]) // Show bottom half of the screen
                                    }
                                }
                                .listSectionSpacing(10)
                                .listRowBackground(getSectionColor().opacity(0.5))
                            }
                            .onChange(of: selectedQueryType) { oldValue, newValue in
                                fetchPostsIfNeeded()
                            }
                        } else {
                            ForEach(networkManager.recentComments.values.sorted(by: { $0.post.title > $1.post.title }), id: \.id) { comment in
                                Section {
                                    commentFrontView(comment: comment)
                                }.background(getSectionColor().opacity(0.5))
                            }
                            .onChange(of: selectedQueryType) { oldValue, newValue in
                                fetchPostsIfNeeded()
                            }
                        }
                     }
            }
        }
    }
    
    @ViewBuilder
    func suggestedSearchView() -> some View {
        Section(header: Text("Suggested")) {
            Button {
                searchModel.tokens.append(.topPosts)
                selectedQueryType = .topPosts
            } label: {
                HStack {
                    Image(systemName: "flame.fill")
                        .padding(.horizontal, 5)
                    Text("Top Posts").foregroundStyle(getColor())
                }
            }
            
            Button {
                searchModel.tokens.append(.newPosts)
                selectedQueryType = .newPosts
            } label: {
                HStack {
                    Image(systemName: "arrow.up")
                        .padding(.horizontal, 5)
                    
                    Text("New Posts").foregroundStyle(getColor())
                }
            }
            
            Button {
                searchModel.tokens.append(.userPosts)
                selectedQueryType = .userPosts
            } label: {
                HStack {
                    Image(systemName: "person.fill")
                        .padding(.horizontal, 5)
                    
                    Text("User").foregroundStyle(getColor())
                }
            }
            
            
            Button {
                searchModel.tokens.append(.comments)
                selectedQueryType = .comments
            } label: {
                HStack {
                    Image(systemName: "bubble.fill")
                        .padding(.horizontal, 5)
                    
                    Text("Comment").foregroundStyle(getColor())
                }
            }
            
        }
    }

    @ViewBuilder
    func postFrontView(post: Post) -> some View {
        NavigationLink(destination: PostDetailView(post: post).environmentObject(networkManager)) {
            VStack() {
                Text(post.title).bold()
                    .padding(.bottom, 2)
//                    .font(.headline)
                    .foregroundColor(getColor())
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("By \(post.author ?? "Unknown")")
//                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.up.fill")
                        Text("\(post.voteCount ?? 0)")
                    }
//                    .font(.subheadline)
                    .foregroundColor(getColor())

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                        Text("\(post.commentCount ?? 0)")
                    }
//                    .font(.subheadline)
                    .foregroundColor(getColor())
                }
            }
            .padding(3)
//            .padding()
            
        }.font(customFont)
        
    }
    
    @ViewBuilder
    func commentFrontView(comment: Comment) -> some View {
        VStack(alignment: .leading) {
            Text(comment.post.title ?? "Unnamed")
                .bold()
                .padding(.bottom, 2)
                .foregroundColor(getColor())
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("By \(comment.user.slug ?? "Anonymous")")
                .foregroundColor(.gray)
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(comment.contents)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.up.fill")
//                    Text("\(comment.currentUserVote ?? 0)")
                }
                .foregroundColor(getColor())

                Spacer()
            }
        }
        .font(customFont)
        .padding()
    }
       
}
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}



