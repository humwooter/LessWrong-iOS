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
                    Button("Edit") {
                        // Edit action
                    }
                    .foregroundColor(.red)
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
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listSectionSpacing(10)
                    .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
                }
//                .listStyle(InsetGroupedListStyle())
                .searchable(text: $searchText, prompt: "Search")
            }
            .scrollContentBackground(.hidden)
            .background {
                ZStack {
                    LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme),getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
                }.ignoresSafeArea(.all)
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button(action: {
                            isPresentingNewFolderSheet = true
                        }) {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewFolderSheet) {
                NewFolderSheet(isPresented: $isPresentingNewFolderSheet, newFolderName: $newFolderName, createFolder: createFolder)
            }
        }
    }

    private func selectFolder(folder: PostFolder) {
        if let post = selectedPost {
            // Check if the selected post already has a folder ID
            if let currentFolderId = post.folderId, let currentFolder = folders.first(where: { $0.id == currentFolderId }) {
                currentFolder.removeFromRelationship(post)
            }
            
            // Set the new folder ID
            selectedPost?.folderId = folder.id
            folder.addToRelationship(post)
            
            // Save the context
            try? viewContext.save()
            
            // Dismiss the folder sheet
            isPresentingNewFolderSheet = false
        }
        presentationMode.wrappedValue.dismiss()
    }


    private func createFolder() {
        guard !newFolderName.isEmpty, !folders.contains(where: { $0.name == newFolderName }) else {
            // Handle empty or duplicate folder name
            print("Folder already exists or name is empty")
            return
        }
        let newFolder = PostFolder(context: viewContext)
        newFolder.id = UUID()
        newFolder.name = newFolderName
        try? viewContext.save()
        newFolderName = ""
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
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
            VStack {
                TextField("New Folder", text: $newFolderName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding()

                Button(action: {
                    createFolder()
                    isPresented = false
                }) {
                    Text("Done")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding()

                Spacer()
            }
            .navigationBarTitle("New Folder", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            })
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme),getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
            }.ignoresSafeArea(.all)
        }
    }
}
