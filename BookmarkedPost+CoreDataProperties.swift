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
