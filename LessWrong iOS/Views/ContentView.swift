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







enum PickerOptions: String, CaseIterable {
    case bookmark = "Bookmark"
    case lessWrong = "LW"
    case effectiveAltruism = "EA"
    case settings = "Settings"
    case search = "Search"
}


struct ContentView: View {
    @State private var selectedOption: PickerOptions = .lessWrong
    @StateObject var networkManager = NetworkManager()
    @State private var selectedItem: String = "TOP"
    @Environment(\.colorScheme) var colorScheme

    var body : some View {
            
            // Your existing view code
            MainView()
                .environmentObject(networkManager)
        .background {
            ZStack {
                LinearGradient(colors: [getTopBackgroundColor(),getBackgroundColor()], startPoint: .top, endPoint: .bottom)
            }.ignoresSafeArea(.all)
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

}

struct MainView: View {
    @EnvironmentObject var networkManager : NetworkManager
    @ObservedObject var searchModel = SearchModel()
    @State private var selectedOption: PickerOptions = .lessWrong
    var showSearch: Binding<Bool> {
          Binding<Bool>(
              get: { self.selectedOption == .search },
              set: { newValue in
                  if newValue {
                      self.selectedOption = .search
                  } else {
                      self.selectedOption = .lessWrong
                  }
              }
          )
      }

    
    var body : some View {
       
        MainChildView(selectedOption: $selectedOption)
            .accentColor(.red)
            .environmentObject(networkManager)
            .environmentObject(searchModel)
            .searchable(text: $searchModel.searchText, tokens: $searchModel.tokens, isPresented: showSearch) { token in
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
    @Binding  var selectedOption: PickerOptions
    @Namespace private var animation

    
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
            VStack {
                Spacer().frame(maxWidth: .infinity, maxHeight: 60)
                    .overlay {
                        horizontalPickerView().frame(maxWidth: .infinity, maxHeight: 60)
                       
                    }
                mainView()

            }
            .background {
                ZStack {
                    LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme),getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
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
                              Task {
                                  await networkManager.fetchPosts(queryType: selectedQueryType, searchText: searchModel.searchText, username: searchModel.searchText, limit: limit)
                              }
                          }
    
                      }
            
            
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
                if !isSearching {
                    fetchPostsIfNeeded()
                }
            }
            .onChange(of: selectedOption) { oldValue, newValue in
                if !isSearching {
                    if newValue != .bookmark {
                        fetchPostsIfNeeded()
                    }
                }
            }
       

            if case .userPosts = selectedQueryType {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
//                    .onChange(of: username) { _ in
//                        fetchPostsIfNeeded()
//                    }
            }

            TextField("Post Limit", text: $postLimit)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
//                .onChange(of: postLimit) { _ in
//                    fetchPostsIfNeeded()
//                }
        } label: {
            Label("Options", systemImage: "slider.horizontal.3")
        }
    }

    private func fetchPostsIfNeeded() {
        if let limit = Int(postLimit) {
            Task {
                // Preserve searchText before fetching
//                let currentSearchText = searchModel.searchText
                await networkManager.fetchPosts(queryType: selectedQueryType, searchText: searchModel.searchText, username: searchModel.searchText, limit: limit)
                // Restore searchText after fetching
//                searchModel.searchText = currentSearchText
            }
        }
    }
    
    func filteredPosts() -> [Post] {
        let posts = networkManager.sortedPosts(by: selectedQueryType, searchText: searchModel.searchText)
        
        switch selectedOption {
        case .lessWrong:
            return posts.filter { $0.url.starts(with: "https://www.lesswrong") }
        case .effectiveAltruism:
            let filtered_posts = posts.filter { !$0.url.starts(with: "https://www.lesswrong") }
            if filtered_posts.isEmpty {
                return posts
            } else {
                return filtered_posts
            }
        default:
            return posts
        }
    }

    
    @ViewBuilder
    func mainView() -> some View {
        if !isSearching {
            if selectedOption == .bookmark {
                BookmarksView()
            } else if selectedOption == .settings {
                BookmarksView()
            } else {
                List {
                    ForEach(filteredPosts().prefix(25), id: \.id) { post in
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
                                        bookmarkPost(post: post)
                                        // Pseudocode for bookmarking the post
                                        // This should eventually add the post URL to a persisted collection
                                        // Example: networkManager.bookmarkPost(post.url)
                                    } label: {
                                        Label("Bookmark", systemImage: "bookmark.fill")
                                    }
                                    .tint(.red)
                                }
                            
                            
                        }
                        .onChange(of: selectedOption) { oldValue, newValue in
                            if newValue.rawValue == "LW" || newValue.rawValue == "EA" {
                                fetchPostsIfNeeded()
                            }
                        }
                        .sheet(isPresented: shouldPresentShareSheet) {
                            ShareSheet(items: [URL(string: selectedURL) as Any])
                                .presentationDetents([.medium]) // Show bottom half of the screen
                        }
                        .listSectionSpacing(10)
                        .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
                    }
                }
            }
        } else {
            
                if searchModel.tokens.isEmpty && searchModel.searchText.isEmpty { //present possible tokens
                    List {
                        suggestedSearchView()
                        
                    }
                }
            else {
                
                
                    List {
         
                        if selectedQueryType != .comments {
                            ForEach(filteredPosts().prefix(25), id: \.id) { post in
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
                                .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
                            }
                            .onChange(of: selectedQueryType) { oldValue, newValue in
                                fetchPostsIfNeeded()
                            }
                        } else {
                            ForEach(networkManager.recentComments.values.sorted(by: { $0.post.title > $1.post.title }), id: \.id) { comment in
                                Section {
                                    commentFrontView(comment: comment)
                                }.background(getSectionColor(colorScheme: colorScheme).opacity(0.5))
                            }
//                            .onChange(of: selectedQueryType) { oldValue, newValue in
//                                fetchPostsIfNeeded()
//                            }
                        }
                     }
//                    .overlay {
//                        VStack {
//                            horizontalPickerView()
//                            Spacer()
//                        }
//                    }
            }
        }
    }
    
    @ViewBuilder
    func horizontalPickerView() -> some View {
        HorizontalPicker(selectedOption: $selectedOption, animation: animation).padding(.top).padding(.leading)
            .frame(maxWidth: .infinity)
//            .background {
//                ZStack {
//                    colorScheme == .dark ? Color.black.opacity(0.9) : getTopBackgroundColor()
//                }.ignoresSafeArea(.all)
//            }
            .onChange(of: selectedOption) { newValue in
                switch newValue {
                case .lessWrong:
                    networkManager.currentEndpoint = "https://www.lesswrong.com/graphql"
                case .effectiveAltruism:
                    networkManager.currentEndpoint = "https://forum.effectivealtruism.org/graphql"
                case .settings:
                    // Navigate to settings view or perform other actions
                    print("Settings selected")
                case .search:
                    print("Settings selected")
                case .bookmark:
                    print("Bookmark")
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
                    Image(systemName: "flame.fill").foregroundStyle(Color.red)
                        .padding(.horizontal, 5)
                    Text("Top Posts").foregroundStyle(getColor(colorScheme: colorScheme))
                }
            }
            
            Button {
                searchModel.tokens.append(.newPosts)
                selectedQueryType = .newPosts
            } label: {
                HStack {
                    Image(systemName: "arrow.up").foregroundStyle(Color.red)
                        .padding(.horizontal, 5)
                    
                    Text("New Posts").foregroundStyle(getColor(colorScheme: colorScheme))
                }
            }
            
            Button {
                searchModel.tokens.append(.userPosts)
                selectedQueryType = .userPosts
            } label: {
                HStack {
                    Image(systemName: "person.fill").foregroundStyle(Color.red)
                        .padding(.horizontal, 5)
                    
                    Text("User").foregroundStyle(getColor(colorScheme: colorScheme))
                }
            }
            
            
            Button {
                searchModel.tokens.append(.comments)
                selectedQueryType = .comments
            } label: {
                HStack {
                    Image(systemName: "bubble.fill").foregroundStyle(Color.red)
                        .padding(.horizontal, 5)
                    
                    Text("Comment").foregroundStyle(getColor(colorScheme: colorScheme))
                }
            }
            
        }
        
    }

    @ViewBuilder
    func postFrontView(post: Post) -> some View {
        NavigationLink(destination: PostDetailView(postURL: post.url).environmentObject(networkManager)) {
            VStack() {
                Text(post.title).bold()
                    .padding(.bottom, 2)
//                    .font(.headline)
                    .foregroundColor(getColor(colorScheme: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("By \(post.author ?? post.slug ?? post.user?.username ?? "Unknown")")
//                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onAppear {
                        print("POST: \(post)")
                    }

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.up.fill")
                        Text("\(post.voteCount ?? 0)")
                    }
//                    .font(.subheadline)
                    .foregroundColor(getColor(colorScheme: colorScheme))

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                        Text("\(post.commentCount ?? 0)")
                    }
//                    .font(.subheadline)
                    .foregroundColor(getColor(colorScheme: colorScheme))
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
                .foregroundColor(getColor(colorScheme: colorScheme))
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
                .foregroundColor(getColor(colorScheme: colorScheme))

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



