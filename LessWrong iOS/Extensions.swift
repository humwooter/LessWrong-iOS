//
//  Extensions.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/3/24.
//

import Foundation
import SwiftUI
import CoreData


struct CustomFontKey: EnvironmentKey {
    static let defaultValue: Font = .custom("Georgia", size: UIFont.systemFontSize)
}

extension EnvironmentValues {
    var customFont: Font {
        get { self[CustomFontKey.self] }
        set { self[CustomFontKey.self] = newValue }
    }
}






extension View {
    @available(iOS 14, *)
    func navigationBarTitleTextColor(_ color: Color) -> some View {
        let uiColor = UIColor(color)
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: uiColor ]
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: uiColor ]
        return self
    }
    
    func setNavigationBarTitleToLightMode() -> some View { //either black or white depending on background color
        UINavigationBar.appearance().overrideUserInterfaceStyle = .light //this works!!
        return self
    }
    
    func customFont(_ font: Font) -> some View {
        environment(\.customFont, font)
    }
}



extension DateFormatter {
    static let postDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()
}
