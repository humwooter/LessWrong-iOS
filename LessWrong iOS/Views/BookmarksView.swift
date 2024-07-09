//
//  BookmarksView.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/6/24.
//


import CoreData
import SwiftUI
import UniformTypeIdentifiers


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
    @State private var selectedFolder: PostFolder?
    @State private var searchText: String = ""
    @State private var isBookmarked = false
    @State private var showingBookmarkAlert = false
    @State private var editMode: EditMode = .inactive
    @State private var editingFolder: PostFolder?
    @State private var newFolderName: String = ""
    
    @State private var showingRenameAlert = false
        @State private var editedFolderName = ""

    
    @State private var showingDeleteConfirmation = false
    @State private var folderToDelete: PostFolder?
    @State var droppedTasks : [String] = []
    @State var targeted: [UUID : Bool] = [:]
    @State var isEditing: [UUID: Bool] = [:]
    @EnvironmentObject var userPreferences: UserPreferences
    
    @State private var isPresentingNewFolderSheet = false
    
    var body: some View {
        List {
                foldersView()
                NavigationLink {
                    recentlyDeletedView()
                } label: {
                    HStack {
                        Image(systemName: "trash").foregroundStyle(.red)
                        Text("Recently Deleted").foregroundStyle(getColor(colorScheme: colorScheme))
                        Spacer()
                    }.frame(maxWidth: .infinity)
                }
//                .listSectionSpacing(10)
                .scrollContentBackground(.hidden)
                .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))

            }

            .navigationTitle("Bookmarked Posts")

            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                        .foregroundStyle(userPreferences.accentColor)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button(action: {
                            newFolderName = ""
                            editingFolder = nil
                            isPresentingNewFolderSheet = true
                        }) {
                            Image(systemName: "folder.badge.plus")
                            .foregroundStyle(userPreferences.accentColor)
                        }
                        Spacer()
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .fullScreenCover(isPresented: $showingFoldersSheet) {
                FoldersView(selectedPost: $selectedPost, accentColor: $userPreferences.accentColor)
            }
            .sheet(isPresented: $isPresentingNewFolderSheet) {
                NewFolderSheet(isPresented: $isPresentingNewFolderSheet, newFolderName: $newFolderName, createFolder: createFolder, editingFolder: $editingFolder, accentColor: $userPreferences.accentColor)
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
            .alert("Rename Folder", isPresented: $showingRenameAlert) {
                 VStack {
                     TextField("Folder Name", text: $editedFolderName)
                     HStack {
                         Button("Save") {
                             if let folder = editingFolder {
                                 folder.name = editedFolderName
                                 try? viewContext.save()
                             }
                             editingFolder = nil
                             showingRenameAlert = false
                         }
                         Button("Cancel", role: .cancel) {
                             editingFolder = nil
                             showingRenameAlert = false
                         }
                     }
                 }.padding()
          }
    }
    
    private func createFolder() {
        guard !newFolderName.isEmpty else { return }
        
        if let folder = editingFolder {
            folder.name = newFolderName
        } else {
            let newFolder = PostFolder(context: viewContext)
            newFolder.id = UUID()
            newFolder.name = newFolderName
            newFolder.order = Int16(folders.count)
        }
        
        try? viewContext.save()
        newFolderName = ""
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
    
    private func saveFolderName(id: UUID, folder: PostFolder) {
         folder.name = editedFolderName
         try? viewContext.save()
         isEditing[id] = false
     }
    
    func isFolderNonExistent(folderId: UUID?, context: NSManagedObjectContext) -> Bool {
        guard let folderId = folderId else {
            return true
        }

        let fetchRequest: NSFetchRequest<PostFolder> = PostFolder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", folderId as CVarArg)

        do {
            let count = try context.count(for: fetchRequest)
            return count == 0
        } catch {
            print("Failed to fetch PostFolder: \(error)")
            return true
        }
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
                                post.isRemoved = false
                                do {
                                    try viewContext.save()
                                } catch {
                                    print("Failed to recover post")
                                }
                               
                            } label: {
                                Label("Recover", systemImage: "arrow.up")
                            }
                            .tint(userPreferences.accentColor)
                        }
                }
                .contextMenu {
                    Button {
                        selectedPost = post
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingFoldersSheet = true
                        }
                    } label: {
                        Label("Add to Folder", systemImage: "folder")
                    }

                }
                .scrollContentBackground(.hidden)
                .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
            }
        }
        .onAppear {
            
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
        List {
//            Section {
                ForEach(bookmarkedPosts.filter {$0.isRemoved != true && isFolderNonExistent(folderId: $0.folderId, context: viewContext)}, id: \.id) { post in
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
                                .tint(userPreferences.accentColor)
                            }
                    }
                    .listSectionSpacing(10)
                }
//            } header: {
//                Text("Bookmarked Posts").font(.custom("Georgia", size: UIFont.systemFontSize * 1.2)).bold()
//            }
            .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
        }
        .listSectionSpacing(10)
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme), getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
            }.ignoresSafeArea(.all)
        }
    }

    @ViewBuilder
    func foldersView() -> some View {
        if !folders.isEmpty {
            Section {
                NavigationLink {
                        bookmarkedPostsView()
                } label: {
                    folderRowView(folder: nil, name: "All Posts")
                }
                ForEach(folders.filter {
                    searchText.isEmpty ? true : $0.name?.localizedCaseInsensitiveContains(searchText) ?? false
                }, id: \.self) { folder in
                    NavigationLink(destination: folderDetailView(folder: folder)) {
                        folderRowView(folder: folder, name: "")
                        
                    }
                    .contextMenu {
                        Button {
                            isEditing[folder.id] = true
                            editingFolder = folder
                            editedFolderName = folder.name ?? ""
                            showingRenameAlert = true
                            
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                    }
                    .dropDestination(for: String.self) { items, location in
                        print("DROPPED TASKS: \(droppedTasks)")
                        guard let transferable = items.first else { return false }
                        droppedTasks.append(transferable)
                        handleDrop(url: URL(string: transferable)! , folder: folder)
                        return true
                    } isTargeted: { isTargeted in
                        targeted[folder.id] = isTargeted
                        if isTargeted {
                            selectedFolder = folder
                        } else {
                            selectedFolder = nil
                        }
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
            .listSectionSpacing(10)
            .scrollContentBackground(.hidden)
            .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
            .listStyle(InsetGroupedListStyle())
        }
    }

 @ViewBuilder
    func folderRowView(folder: PostFolder?, name: String?) -> some View {
        if let folder = folder {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(targeted[folder.id] == true ? .green : userPreferences.accentColor.opacity(1))
        
                 Text(folder.name ?? "Unnamed") .foregroundColor(getColor(colorScheme: colorScheme))
                Spacer()
                Text("\(folder.relationship?.count ?? 0)")
                    .foregroundColor(.gray)
                    .dropDestination(for: String.self) { items, location in
                        print("DROPPED TASKS: \(droppedTasks)")
                        guard let transferable = items.first else { return false }
                        droppedTasks.append(transferable)
                        handleDrop(url: URL(string: transferable)! , folder: folder)
                        return true
                    } isTargeted: { isTargeted in
                        targeted[folder.id] = isTargeted
                    }
            }
        } else { //The case for all posts
            HStack {
                Image(systemName: "folder.fill").foregroundStyle(userPreferences.accentColor.opacity(1))
//                    .foregroundStyle(getColor(colorScheme: colorScheme))
                Text(name ?? "") .foregroundStyle(getColor(colorScheme: colorScheme))
                Spacer()
                Text("\(bookmarkedPosts.count ?? 0)")
                    .foregroundColor(.gray)
            }
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
        .padding(.horizontal)
        .padding(.vertical)
        .padding(3)
        .font(customFont)
    }
    .draggable(post.url!, preview: {
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title ?? "Unnamed")
                    .bold()
                    .foregroundColor(getColor(colorScheme: colorScheme))
                Text("By \(post.author ?? "Unknown")")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical)
            .font(customFont)
            .cornerRadius(30)
})
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
                            .tint(userPreferences.accentColor)
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
    

    func handleDrop(url: URL, folder: PostFolder) {
        print("entered handle drop")

        // Create a fetch request for BookmarkedPost
        let fetchRequest: NSFetchRequest<BookmarkedPost> = BookmarkedPost.fetchRequest()
        
        // Set the predicate to filter by the url
        fetchRequest.predicate = NSPredicate(format: "url == %@", url.absoluteString)
        
        do {
            // Perform the fetch request
            let results = try viewContext.fetch(fetchRequest)
            
            // Check if a post was found
            if let post = results.first {
                post.folderId = folder.id
                folder.addToRelationship(post)
                try viewContext.save()
            }
        } catch {
            print("Failed to fetch BookmarkedPost: \(error)")
        }
    }

}

