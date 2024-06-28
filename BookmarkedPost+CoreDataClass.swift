//
//  BookmarkedPost+CoreDataClass.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/8/24.
//
//

import Foundation
import CoreData

@objc(BookmarkedPost)
public class BookmarkedPost: NSManagedObject, Codable {
    required public convenience init(from decoder: Decoder) throws {
         // Ensure there is a context available for the current thread
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
          }
         
         // Call the designated initializer
        self.init(context: context)

         let container = try decoder.container(keyedBy: CodingKeys.self)
         self.author = try container.decodeIfPresent(String.self, forKey: .author)
         self.isRemoved = try container.decode(Bool.self, forKey: .isRemoved)
         self.commentCount = try container.decode(Int16.self, forKey: .commentCount)
         self.dateSaved = try container.decodeIfPresent(Date.self, forKey: .dateSaved)
         self.folderId = try container.decodeIfPresent(UUID.self, forKey: .folderId)
         self.id = try container.decodeIfPresent(String.self, forKey: .id)
         self.title = try container.decodeIfPresent(String.self, forKey: .title)
         self.url = try container.decodeIfPresent(String.self, forKey: .url)
         self.voteCount = try container.decode(Int16.self, forKey: .voteCount)
     }
     
     public func encode(to encoder: Encoder) throws {
         var container = encoder.container(keyedBy: CodingKeys.self)
         try container.encodeIfPresent(author, forKey: .author)
         try container.encode(isRemoved, forKey: .isRemoved)
         try container.encode(commentCount, forKey: .commentCount)
         try container.encodeIfPresent(dateSaved, forKey: .dateSaved)
         try container.encodeIfPresent(folderId, forKey: .folderId)
         try container.encodeIfPresent(id, forKey: .id)
         try container.encodeIfPresent(title, forKey: .title)
         try container.encodeIfPresent(url, forKey: .url)
         try container.encode(voteCount, forKey: .voteCount)
     }
     
     private enum CodingKeys: String, CodingKey {
         case author, isRemoved, commentCount, dateSaved, folderId, id, title, url, voteCount
     }
}
