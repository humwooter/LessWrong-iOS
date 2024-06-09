//
//  BookmarksView.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/6/24.
//


import CoreData



import SwiftUI

struct BookmarksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: BookmarkedPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedPost.title, ascending: true)]
    ) var bookmarkedPosts: FetchedResults<BookmarkedPost>
    @FetchRequest(
        entity: PostFolder.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PostFolder.name, ascending: true)]
    ) var folders: FetchedResults<PostFolder>
    @EnvironmentObject var networkManager: NetworkManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.customFont) var customFont: Font
    @State private var showingFoldersSheet = false
    @State private var selectedPost: BookmarkedPost?
    @State private var searchText: String = ""
    @State private var isBookmarked = false
    @State private var showingBookmarkAlert = false
       @State private var editMode: EditMode = .inactive
       @State private var editingFolder: PostFolder?
       @State private var newFolderName: String = ""
    
    
    var body: some View {

            List {
                if !folders.isEmpty {
                    Section {
                        ForEach(folders.filter {
                            searchText.isEmpty ? true : $0.name?.localizedCaseInsensitiveContains(searchText) ?? false
                        }, id: \.self) { folder in
                            NavigationLink(destination: folderDetailView(folder: folder)) {
                                folderRowView(folder: folder)
                            }
                        }
                        .onDelete(perform: deleteFolders)
                                    .onMove(perform: moveFolders)
                    } header: {
                        Text("Folders").font(.custom("Georgia", size: UIFont.systemFontSize * 1.2)).bold()
                    } footer: {
                        Spacer(minLength: 20)
                    }
                  
                    .listSectionSpacing(5)
                    .scrollContentBackground(.hidden)
                    .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
                }
                
                Section {
                    ForEach(bookmarkedPosts.filter { $0.folderId == nil }, id: \.id) { post in
                        Section {
                            postFrontView(post: post)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        // Add share functionality here
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    .tint(.cyan)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        if !showingFoldersSheet {
                                            selectedPost = post
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                showingFoldersSheet = true
                                            }
                                        }
                                    } label: {
                                        Label("Add to Folder", systemImage: "folder")
                                    }
                                    .tint(.red)
                                }
                        }
                        .listSectionSpacing(10)
                    }
                } header: {
                    Text("Bookmarked Posts").font(.custom("Georgia", size: UIFont.systemFontSize * 1.2)).bold()
                }
               
                .scrollContentBackground(.hidden)
                .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
            }
            .listStyle(InsetGroupedListStyle())
//            .searchable(text: $searchText, prompt: "Search")
            .navigationTitle("Bookmarked Posts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                        .foregroundColor(.red)
                }
            }
            .environment(\.editMode, $editMode)

            .fullScreenCover(isPresented: $showingFoldersSheet) {
                FoldersView(selectedPost: $selectedPost)
            }
        
    }
    
    private func renameFolder() {
          if let folder = editingFolder {
              folder.name = newFolderName
              try? viewContext.save()
          }
          editingFolder = nil
          showingFoldersSheet = false
      }

      private func deleteFolder(folder: PostFolder) {
          viewContext.delete(folder)
          try? viewContext.save()
      }

      private func deleteFolders(at offsets: IndexSet) {
          for index in offsets {
              let folder = folders[index]
              viewContext.delete(folder)
          }
          try? viewContext.save()
      }

      private func moveFolders(from source: IndexSet, to destination: Int) {
          var revisedFolders = folders.map { $0 }
          revisedFolders.move(fromOffsets: source, toOffset: destination)
          
          // Update the order in CoreData
          for reverseIndex in stride(from: revisedFolders.count - 1, through: 0, by: -1) {
              revisedFolders[reverseIndex].order = Int16(reverseIndex)
          }
          try? viewContext.save()
      }

    @ViewBuilder
    func folderRowView(folder: PostFolder) -> some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.red)
            Text(folder.name ?? "Unnamed")
            Spacer()
            Text("\(folder.relationship?.count ?? 0)")
                .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    func postFrontView(post: BookmarkedPost) -> some View {
        NavigationLink(destination: PostDetailView(postURL: post.url ?? "").environmentObject(networkManager)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title ?? "Unnamed")
                    .bold()
                    .foregroundColor(getColor(colorScheme: colorScheme))
                Text("By \(post.author ?? "Unknown")")
                    .foregroundColor(.gray)
                HStack {
                    voteCountView(post: post)
                    Spacer()
                    commentCountView(post: post)
                }
            }
            .padding(3)
            .font(customFont)
        }
    }

    @ViewBuilder
    func folderDetailView(folder: PostFolder) -> some View {
            List {
                ForEach(folder.relationship?.allObjects as? [BookmarkedPost] ?? []) { post in
                    Section {
                        postFrontView(post: post)
                            .swipeActions(edge: .leading) {
                                Button {
                                    if !showingFoldersSheet {
                                        selectedPost = post
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            showingFoldersSheet = true
                                        }
                                    }
                                } label: {
                                    Label("Add to Folder", systemImage: "folder")
                                }
                                .tint(.red)
                            }
                    }
                    .listSectionSpacing(10)
            .scrollContentBackground(.hidden)
            .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
                }
            }
        .navigationTitle(folder.name ?? "Folder")
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme),getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
            }.ignoresSafeArea(.all)
        }
    }
    
    @ViewBuilder
    func voteCountView(post: BookmarkedPost) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "arrowshape.up.fill")
            Text("\(post.voteCount ?? 0)")
        }
        .foregroundColor(getColor(colorScheme: colorScheme))
    }

    @ViewBuilder
    func commentCountView(post: BookmarkedPost) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "message.fill")
            Text("\(post.commentCount ?? 0)")
        }
        .foregroundColor(getColor(colorScheme: colorScheme))
    }
}

func bookmarkPost(post: Post) -> Bool {
    let viewContext = PersistenceController.shared.container.viewContext
    let fetchRequest: NSFetchRequest<BookmarkedPost> = BookmarkedPost.fetchRequest()
    
    // Simplifying the predicate to check by URL or ID
    fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
        NSPredicate(format: "id == %@", post.id ?? ""),
        NSPredicate(format: "url == %@", post.url ?? "")
    ])
    
    do {
        let existingPosts = try viewContext.fetch(fetchRequest)
        if let existingPost = existingPosts.first {
            // Remove the post from any folders it belongs to
            if let folders = existingPost.relationship as? Set<PostFolder> {
                for folder in folders {
                    folder.removeFromRelationship(existingPost)
                }
            }
            
            // If the post is already bookmarked, delete it
            viewContext.delete(existingPost)
            try viewContext.save()
            print("Bookmark removed successfully")
            return false
        } else {
            // If the post is not bookmarked, create a new bookmark
            let newBookmark = BookmarkedPost(context: viewContext)
            newBookmark.id = post.id
            newBookmark.dateSaved = Date()
            newBookmark.url = post.url
            newBookmark.title = post.title
            newBookmark.author = post.author
            newBookmark.voteCount = Int16(post.voteCount ?? 0)
            newBookmark.commentCount = Int16(post.commentCount ?? 0)

            // Optionally add to a specific folder if needed
            // Example: if let folder = findFolderById(folderId) {
            //     folder.addToRelationship(newBookmark)
            // }

            try viewContext.save()
            print("Bookmark saved successfully")
            return true
        }
    } catch {
        print("Failed to manage bookmark: \(error)")
        return false
    }
}




//struct BookmarksView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    @FetchRequest(
//        entity: BookmarkedPost.entity(),
//        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedPost.title, ascending: true)]
//    ) var bookmarkedPosts: FetchedResults<BookmarkedPost>
//    @EnvironmentObject var networkManager: NetworkManager
//    @Environment(\.colorScheme) var colorScheme
//    @Environment(\.customFont) var customFont: Font
//
//    @State private var showingFoldersSheet = false
//    @State private var selectedPost: BookmarkedPost?
//
//    var body: some View {
//        List(bookmarkedPosts, id: \.id) { post in
//            Section {
//                postFrontView(post: post)
//                    .swipeActions(edge: .trailing) {
//                        Button {
//                            // Add share functionality here
//                        } label: {
//                            Label("Share", systemImage: "square.and.arrow.up")
//                        }
//                        .tint(.cyan)
//                    }
//                    .swipeActions(edge: .leading) {
//                                         Button {
//                                             if !showingFoldersSheet {
//                                                 selectedPost = post
//                                                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                                                     showingFoldersSheet = true
//                                                 }
//                                             }
//                                         } label: {
//                                             Label("Add to Folder", systemImage: "folder")
//                                         }
//                                         .tint(.blue)
//                                     }
//        
//            }
//            .listSectionSpacing(10)
//            .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
//        }
//        .sheet(isPresented: $showingFoldersSheet) {
//            FoldersView(selectedPost: $selectedPost)
//        }
//        .navigationTitle("Bookmarked Posts")
//    }
//
//    @ViewBuilder
//    func postFrontView(post: BookmarkedPost) -> some View {
//        NavigationLink(destination: PostDetailView(postURL: post.url ?? "").environmentObject(networkManager)) {
//            VStack {
//                Text(post.title ?? "Unnamed").bold()
//                    .padding(.bottom, 2)
//                    .foregroundColor(getColor(colorScheme: colorScheme))
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                Text("By \(post.author ?? "Unknown")")
//                    .foregroundColor(.gray)
//                    .padding(.bottom, 2)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//
//                HStack {
//                    HStack(spacing: 4) {
//                        Image(systemName: "arrowshape.up.fill")
//                        Text("\(post.voteCount ?? 0)")
//                    }
//                    .foregroundColor(getColor(colorScheme: colorScheme))
//
//                    Spacer()
//
//                    HStack(spacing: 4) {
//                        Image(systemName: "message.fill")
//                        Text("\(post.commentCount ?? 0)")
//                    }
//                    .foregroundColor(getColor(colorScheme: colorScheme))
//                }
//            }
//            .padding(3)
//        }
//        .font(customFont)
//    }
//}
//
//
//
//func bookmarkPost(post: Post) {
//    let viewContext = PersistenceController.shared.container.viewContext
//    let fetchRequest: NSFetchRequest<BookmarkedPost> = BookmarkedPost.fetchRequest()
//    
//    // Check if a post with the same id, url, or title already exists
//    fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
//        NSPredicate(format: "id == %@", post.id),
//        NSPredicate(format: "url == %@", post.url),
//        NSPredicate(format: "title == %@", post.title)
//    ])
//    
//    do {
//        let existingPosts = try viewContext.fetch(fetchRequest)
//        if !existingPosts.isEmpty {
//            print("Post already bookmarked")
//            return
//        }
//        
//        // If the post does not exist, create a new bookmark
//        let newBookmark = BookmarkedPost(context: viewContext)
//        newBookmark.id = post.id
//        newBookmark.dateSaved = Date()
//        newBookmark.url = post.url
//        newBookmark.title = post.title
//        newBookmark.author = post.author
//        newBookmark.voteCount = Int16(post.voteCount ?? 0)
//        newBookmark.commentCount = Int16(post.commentCount ?? 0)
//
//        try viewContext.save()
//        print("Bookmark saved successfully")
//    } catch {
//        print("Failed to save bookmark: \(error)")
//    }
//}
