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
    @StateObject var networkManager = NetworkManager()
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedQueryType: QueryType = .topPosts
    @State private var postLimit: String = "10"
    @State private var username: String = "User"
    @StateObject private var searchModel = SearchModel()
    @Environment(\.customFont) var customFont: Font
    
    var body: some View {
        NavigationView {
            mainView()
                .background {
                    ZStack {
                        LinearGradient(colors: [getTopBackgroundColor(),getBackgroundColor()], startPoint: .top, endPoint: .bottom)
                    }.ignoresSafeArea(.all)
                }
                
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
            return .white.opacity(0.1)
        }
    }
    
    @ViewBuilder
    func toolBarMenu() -> some View {
        Menu {
            Picker("Query Type", selection: $selectedQueryType) {
                Text("Top Posts").tag(QueryType.topPosts)
                Text("New Posts").tag(QueryType.newPosts)
                Text("User Posts").tag(QueryType.userPosts)
            }
            if case .userPosts = selectedQueryType {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
            TextField("Post Limit", text: $postLimit)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                if let limit = Int(postLimit) {
                    networkManager.fetchPosts(queryType: selectedQueryType, searchText: searchModel.searchText, username: username, limit: limit)
                }
            }) {
                Text("Apply")
            }
        } label: {
            Label("Options", systemImage: "slider.horizontal.3")
        }
    }
    
    @ViewBuilder
    func mainView() -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(networkManager.posts) { post in
                    Section {
                        postFrontView(post: post)
                    }.background(getSectionColor().opacity(0.5))
                }
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .searchable(text: $searchModel.searchText, tokens: $searchModel.tokens) { token in
                        switch token {
                        case .newPosts:
                            Text("New Posts")
                        case .topPosts:
                            Text("Top Posts")
                        case .userPosts:
                            Text("User")
                        }
                
                
            }
            .setNavigationBarTitleToLightMode()

        }
    }
    
    @ViewBuilder
    func suggestedSearchView() -> some View {
        Section(header: Text("Suggested")) {
            Button {
                searchModel.tokens.append(.topPosts)
            } label: {
                HStack {
                    Image(systemName: "eye.fill")
                        .padding(.horizontal, 5)
                    Text("Top Posts")
                        .foregroundStyle(Color(UIColor.label))
                }
            }
            
            Button {
                searchModel.tokens.append(.newPosts)
            } label: {
                HStack {
                    Image(systemName: "paperclip")
                        .padding(.horizontal, 5)
                    
                    Text("Entries with Media")
                        .foregroundStyle(Color(UIColor.label))
                }
            }
            
            Button {
                searchModel.tokens.append(.userPosts)
            } label: {
                HStack {
                    Image(systemName: "bell.fill")
                        .padding(.horizontal, 5)
                    
                    Text("Entries with Reminder")
                        .foregroundStyle(Color(UIColor.label))
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
            .padding()
        }.font(customFont)
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



