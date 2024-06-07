//
//  BookmarksView.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/6/24.
//


import SwiftUI
import CoreData


struct BookmarksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: BookmarkedPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedPost.title, ascending: true)]
    ) var bookmarkedPosts: FetchedResults<BookmarkedPost>
    @EnvironmentObject var networkManager: NetworkManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.customFont) var customFont: Font


    var body: some View {
        List(bookmarkedPosts, id: \.id) { post in
            Section {
                postFrontView(post: post)
                    .swipeActions(edge: .trailing) {
                        Button {
                            //                                selectedURL = post.url
                            //                                // Pseudocode for sharing the post
                            //                                showingShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.cyan)
                        
                    }
             
                
                
            }
            .listSectionSpacing(10)
            .listRowBackground(getSectionColor(colorScheme: colorScheme).opacity(0.5))
        }

        .navigationTitle("Bookmarked Posts")
    }

    
    @ViewBuilder
    func postFrontView(post: BookmarkedPost) -> some View {
        NavigationLink(destination: PostDetailView(postURL: post.url ?? "").environmentObject(networkManager)) {
            VStack() {
                Text(post.title ?? "Unnamed").bold()
                    .padding(.bottom, 2)
//                    .font(.headline)
                    .foregroundColor(getColor(colorScheme: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("By \(post.author ?? "Unknown")")
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
}

struct BookmarkedPostView: View {
    var bookmark: BookmarkedPost

    var body: some View {
        VStack(alignment: .leading) {
            Text(bookmark.title ?? "Untitled")
                .bold()
                .foregroundColor(.primary)
                .padding(.bottom, 2)

            Text("By \(bookmark.author ?? "Unknown")")
                .foregroundColor(.secondary)
                .padding(.bottom, 2)

            HStack {
                Image(systemName: "hand.thumbsup")
                Text("\(bookmark.voteCount)")
                Spacer()
                Image(systemName: "text.bubble")
                Text("\(bookmark.commentCount)")
            }
            .foregroundColor(.gray)
            .padding(.vertical, 4)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

func bookmarkPost(post: Post) {
    let viewContext = PersistenceController.shared.container.viewContext
    let fetchRequest: NSFetchRequest<BookmarkedPost> = BookmarkedPost.fetchRequest()
    
    // Check if a post with the same id, url, or title already exists
    fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
        NSPredicate(format: "id == %@", post.id),
        NSPredicate(format: "url == %@", post.url),
        NSPredicate(format: "title == %@", post.title)
    ])
    
    do {
        let existingPosts = try viewContext.fetch(fetchRequest)
        if !existingPosts.isEmpty {
            print("Post already bookmarked")
            return
        }
        
        // If the post does not exist, create a new bookmark
        let newBookmark = BookmarkedPost(context: viewContext)
        newBookmark.id = post.id
        newBookmark.dateSaved = Date()
        newBookmark.url = post.url
        newBookmark.title = post.title
        newBookmark.author = post.author
        newBookmark.voteCount = Int16(post.voteCount ?? 0)
        newBookmark.commentCount = Int16(post.commentCount ?? 0)

        try viewContext.save()
        print("Bookmark saved successfully")
    } catch {
        print("Failed to save bookmark: \(error)")
    }
}
