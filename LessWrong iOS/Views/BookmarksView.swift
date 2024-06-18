//
//  BookmarksView.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/6/24.
//


import CoreData
import SwiftUI
import UniformTypeIdentifiers

struct BookmarkedPostTransferable: Transferable, Codable {
    let uri: URL

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .url)
    }
}

extension BookmarkedPost {
    var transferable: BookmarkedPostTransferable {
        BookmarkedPostTransferable(uri: objectID.uriRepresentation())
    }
}

struct BookmarksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: BookmarkedPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedPost.title, ascending: true)]
    ) var bookmarkedPosts: FetchedResults<BookmarkedPost>
    
    @FetchRequest(
        entity: BookmarkedPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedPost.title, ascending: true)],
        predicate: NSPredicate(format: "isRemoved == %@", NSNumber(value: true))
    ) var deletedPosts: FetchedResults<BookmarkedPost>

    
    @FetchRequest(
        entity: PostFolder.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \PostFolder.order, ascending: true),
            NSSortDescriptor(keyPath: \PostFolder.name, ascending: true) // Secondary sort by name
        ]
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
    @State private var showingDeleteConfirmation = false
    @State private var folderToDelete: PostFolder?

    var body: some View {
            List {
                foldersView()
                bookmarkedPostsView()
                NavigationLink {
                    recentlyDeletedView()
                } label: {
                    Label("Recently Deleted", systemImage: "trash")
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
            }
//            .scrollContentBackground(.hidden)
//            .background {
//                ZStack {
//                    LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme), getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
//                }.ignoresSafeArea(.all)
//            }
            .listStyle(InsetGroupedListStyle())
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
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Folder"),
                    message: Text("Are you sure you want to delete this folder? All associated posts will be marked as removed."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let folder = folderToDelete {
                            markPostsAsRemoved(for: folder)
                            deleteFolder(folder: folder)
                        }
                    },
                    secondaryButton: .cancel()
                )
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
        markPostsAsRemoved(for: folder)
        viewContext.delete(folder)
        try? viewContext.save()
    }

    private func markPostsAsRemoved(for folder: PostFolder) {
        if let posts = folder.relationship as? Set<BookmarkedPost> {
            for post in posts {
                post.isRemoved = true
            }
        }
        try? viewContext.save()
    }

    private func deleteFolders(at offsets: IndexSet) {
        for index in offsets {
            let folder = folders[index]
            markPostsAsRemoved(for: folder)
            viewContext.delete(folder)
        }
        try? viewContext.save()
    }

    private func moveFolders(from source: IndexSet, to destination: Int) {
        var revisedFolders = folders.map { $0 }
        revisedFolders.move(fromOffsets: source, toOffset: destination)
        
        for index in revisedFolders.indices {
            revisedFolders[index].order = Int16(index)
        }

        try? viewContext.save()
    }
    
    @ViewBuilder
    func recentlyDeletedView() -> some View {
        
        var filteredDeletedPosts: [BookmarkedPost] {
            if searchText.isEmpty {
                return Array(deletedPosts)
            } else {
                return deletedPosts.filter { $0.title?.lowercased().contains(searchText.lowercased()) ?? false }
            }
        }
        List() {
            Section(header: Text("Posts are available here for 10 days, after which they will be permanently deleted").textCase(.none)
                .font(.caption)
                .frame(maxWidth: .infinity)
            ) {}
            
            ForEach(filteredDeletedPosts, id: \.self) { post in
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
                .scrollContentBackground(.hidden)
                .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme), getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
            }.ignoresSafeArea(.all)
        }
        .navigationTitle("Recently Deleted")
    }
    
    @ViewBuilder
    func bookmarkedPostsView() -> some View {
        Section {
            ForEach(bookmarkedPosts.filter { $0.folderId == nil && !$0.isRemoved }, id: \.id) { post in
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
                .draggable(post.url ?? "", preview: {
                    postFrontView(post: post)
                })
                .listSectionSpacing(10)
            }
        } header: {
            Text("Bookmarked Posts").font(.custom("Georgia", size: UIFont.systemFontSize * 1.2)).bold()
        }
        .scrollContentBackground(.hidden)
        .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
    }

    @ViewBuilder
    func foldersView() -> some View {
        if !folders.isEmpty {
            Section {
                ForEach(folders.filter {
                    searchText.isEmpty ? true : $0.name?.localizedCaseInsensitiveContains(searchText) ?? false
                }, id: \.self) { folder in
                    NavigationLink(destination: folderDetailView(folder: folder)) {
                        folderRowView(folder: folder)
                    }
                    .dropDestination(for: BookmarkedPostTransferable.self) { items, location in
                        print("IN DROP DESTINATION")
                        guard let transferable = items.first else { return false }
                        handleDrop(transferable: transferable, folder: folder)
                        return true
                    }

                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            folderToDelete = folder
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
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
    .onDrop(of: [UTType.url], isTargeted: nil) { providers in
        providers.first?.loadObject(ofClass: URL.self) { url, error in
            if let url = url {
                DispatchQueue.main.async {
                    self.handleDrop(url: url, folder: folder)
                }
            }
        }
        return true
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
//    .draggable(post.transferable)
//    .draggable(Image(systemName: "heart"))
}
    @ViewBuilder
    func folderDetailView(folder: PostFolder) -> some View {
        List {
            ForEach((folder.relationship?.allObjects as? [BookmarkedPost] ?? []).filter { !$0.isRemoved }) { post in
                Section {
                    postFrontView(post: post)
                        .swipeActions(edge: .leading) {
                            Button {
                                if (!showingFoldersSheet) {
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
                LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme), getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
            }.ignoresSafeArea(.all)
        }
    }

    @ViewBuilder
    func voteCountView(post: BookmarkedPost) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "arrowshape.up.fill")
            Text("\(post.voteCount)")
        }
        .foregroundColor(getColor(colorScheme: colorScheme))
    }

    @ViewBuilder
    func commentCountView(post: BookmarkedPost) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "message.fill")
            Text("\(post.commentCount)")
        }
        .foregroundColor(getColor(colorScheme: colorScheme))
    }
    
private func handleDrop(transferable: BookmarkedPostTransferable, folder: PostFolder) {
    print("entered handle drop")
    let uri = transferable.uri
    if let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri),
       let post = try? viewContext.existingObject(with: objectID) as? BookmarkedPost {
        post.folderId = folder.id
        try? viewContext.save()
    }
}

private func handleDrop(url: URL, folder: PostFolder) {
    print("entered handle drop")
    guard let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
          let post = try? viewContext.existingObject(with: objectID) as? BookmarkedPost else {
        return
    }
    post.folderId = folder.id
    try? viewContext.save()
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
