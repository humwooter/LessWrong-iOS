//
//  UserPreferences.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/8/24.
//

import Foundation
import SwiftUI
import Combine

class UserPreferences: ObservableObject, Codable {
    enum CodingKeys: CodingKey {
        case accentColor
    }

    @Published var accentColor: Color {
        didSet {
            UserDefaults.standard.setColor(color: accentColor, forKey: "accentColor")
        }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accentColor = try container.decode(Color.self, forKey: .accentColor)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accentColor, forKey: .accentColor)
    }

    init() {
        self.accentColor = UserDefaults.standard.color(forKey: "accentColor") ?? .red // Default color
    }
}

extension KeyedDecodingContainer {
    func decode(_ type: Color.Type, forKey key: Key) throws -> Color {
        let colorData = try self.decode(Data.self, forKey: key)
        guard let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Color data corrupted")
        }
        return Color(uiColor)
    }
}

extension KeyedEncodingContainer {
    mutating func encode(_ value: Color, forKey key: Key) throws {
        let uiColor = UIColor(value)
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        try self.encode(colorData, forKey: key)
    }
}

extension UserDefaults {
    func setColor(color: Color, forKey key: String) {
        let uiColor = UIColor(color)
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
            set(data, forKey: key)
        } catch {
            print("Error archiving color: \(error)")
        }
    }

    func color(forKey key: String) -> Color? {
        guard let data = data(forKey: key) else { return nil }
        do {
            if let uiColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
                return Color(uiColor)
            }
        } catch {
            print("Failed to unarchive UIColor: \(error)")
        }
        return nil
    }
}
