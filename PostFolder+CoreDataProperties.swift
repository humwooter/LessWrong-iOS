//
//  PostFolder+CoreDataProperties.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/8/24.
//
//

import Foundation
import CoreData


extension PostFolder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostFolder> {
        return NSFetchRequest<PostFolder>(entityName: "PostFolder")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var relationship: NSSet?

}

// MARK: Generated accessors for relationship
extension PostFolder {

    @objc(addRelationshipObject:)
    @NSManaged public func addToRelationship(_ value: BookmarkedPost)

    @objc(removeRelationshipObject:)
    @NSManaged public func removeFromRelationship(_ value: BookmarkedPost)

    @objc(addRelationship:)
    @NSManaged public func addToRelationship(_ values: NSSet)

    @objc(removeRelationship:)
    @NSManaged public func removeFromRelationship(_ values: NSSet)

}

extension PostFolder : Identifiable {

}
