//
//  PostFolder+CoreDataClass.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/8/24.
//
//

import Foundation
import CoreData


enum DecoderConfigurationError: Error {
  case missingManagedObjectContext
}


extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}



@objc(PostFolder)
public class PostFolder: NSManagedObject, Codable {
    required public convenience init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
          }

          self.init(context: context)

        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decodeIfPresent(UUID.self, forKey: .id)!
        name = try values.decodeIfPresent(String.self, forKey: .name)!
        name = try values.decodeIfPresent(String.self, forKey: .order)!

        relationship = try (values.decode(Set<BookmarkedPost>?.self, forKey: .relationship) as NSSet?)!
    }
    
    public func encode(to encoder: Encoder) throws {
        print("entry: \(self)")
     
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(String(order), forKey: .order)
        try container.encodeIfPresent(name, forKey: .name)
        if let relationshipSet = relationship as? Set<BookmarkedPost> {
            try container.encode(relationshipSet, forKey: .relationship)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, order, relationship
    }
}
