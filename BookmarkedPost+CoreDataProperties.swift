//
//  BookmarkedPost+CoreDataProperties.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/8/24.
//
//

import Foundation
import CoreData


extension BookmarkedPost {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BookmarkedPost> {
        return NSFetchRequest<BookmarkedPost>(entityName: "BookmarkedPost")
    }

    @NSManaged public var author: String?
    @NSManaged public var isRemoved: Bool
    @NSManaged public var commentCount: Int16
    @NSManaged public var dateSaved: Date?
    @NSManaged public var folderId: UUID?
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var voteCount: Int16
    @NSManaged public var relationship: PostFolder?

}

extension BookmarkedPost : Identifiable {

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
            newBookmark.isRemoved = false

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
