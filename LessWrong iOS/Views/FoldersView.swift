//
//  FoldersView.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/8/24.
//

import SwiftUI
import CoreData

struct FoldersView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: PostFolder.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PostFolder.name, ascending: true)]
    ) var folders: FetchedResults<PostFolder>
    @Binding var selectedPost: BookmarkedPost?
    @State private var newFolderName: String = ""
    @State private var searchText: String = ""
    @State private var isPresentingNewFolderSheet = false
    @State private var editingFolder: PostFolder?
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Folders")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                }
                .padding()

                List {
                    Section(header: Text("Folders")) {
                        ForEach(folders.filter {
                            searchText.isEmpty ? true : $0.name?.localizedCaseInsensitiveContains(searchText) ?? false
                        }, id: \.self) { folder in
                            FolderRow(name: folder.name ?? "Unnamed", icon: "folder", count: folder.relationship?.count ?? 0, folderId: folder.id, selectFolder: {
                                selectFolder(folder: folder)
                            })
                            .contextMenu {
                                Button("Rename") {
                                    editingFolder = folder
                                    newFolderName = folder.name ?? ""
                                    isPresentingNewFolderSheet = true
                                }
                                Button("Delete", role: .destructive) {
                                    deleteFolder(folder: folder)
                                }
                            }
                        }
                        .onDelete(perform: deleteFolders)
                        .onMove(perform: moveFolders)
                    }
                    .scrollContentBackground(.hidden)
                    .listSectionSpacing(10)
                    .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }.foregroundStyle(.red)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                            .foregroundColor(.red)
                    }
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            Button(action: {
                                newFolderName = ""
                                editingFolder = nil
                                isPresentingNewFolderSheet = true
                            }) {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search")
            }
            .scrollContentBackground(.hidden)
            .background {
                ZStack {
                    LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme), getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
                }.ignoresSafeArea(.all)
            }
            .sheet(isPresented: $isPresentingNewFolderSheet) {
                NewFolderSheet(isPresented: $isPresentingNewFolderSheet, newFolderName: $newFolderName, createFolder: createFolder, editingFolder: $editingFolder)
            }
        }
    }
    
    private func selectFolder(folder: PostFolder) {
           if let post = selectedPost {
               // Check if the selected post already has a folder ID
               if let currentFolderId = post.folderId, let currentFolder = folders.first(where: { $0.id == currentFolderId }) {
                   currentFolder.removeFromRelationship(post)
                   post.folderId = nil
               }
               else {
                   // Set the new folder ID
                   selectedPost?.folderId = folder.id
                   folder.addToRelationship(post)
               }
               // Save the context
               try? viewContext.save()
               
               // Dismiss the folder sheet
               isPresentingNewFolderSheet = false
           }
           presentationMode.wrappedValue.dismiss()
       }

    private func createFolder() {
        guard !newFolderName.isEmpty else { return }
        
        if let folder = editingFolder {
            folder.name = newFolderName
        } else {
            let newFolder = PostFolder(context: viewContext)
            newFolder.id = UUID()
            newFolder.name = newFolderName
            newFolder.order = Int16(folders.count ?? 0)
        }

        try? viewContext.save()
        newFolderName = ""
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
}

struct FolderRow: View {
    let name: String
    let icon: String
    let count: Int
    let folderId: UUID?
    let selectFolder: () -> Void

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.red)
            Text(name)
            Spacer()
            Text("\(count)")
                .foregroundColor(.gray)
            Button(action: selectFolder) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 5)
    }
}

struct NewFolderSheet: View {
    @Binding var isPresented: Bool
    @Binding var newFolderName: String
    let createFolder: () -> Void
    @Binding var editingFolder: PostFolder?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            List {
                TextField("New Folder", text: $newFolderName).foregroundStyle(colorScheme == .dark ? .white : .black)
                    .cornerRadius(8)
            }
            .navigationBarTitle(editingFolder == nil ? "New Folder" : "Rename Folder", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Done") {
                createFolder()
                isPresented = false
            })
            .scrollContentBackground(.hidden)
            .background {
                ZStack {
                    LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme), getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
                }.ignoresSafeArea(.all)
            }
            .foregroundStyle(.red)
        }
    }
}
