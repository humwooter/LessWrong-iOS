//
//  LessWrong_iOSApp.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/2/24.
//

import SwiftUI

@main
struct LessWrong_iOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .customFont(.custom("Georgia", size: UIFont.systemFontSize))

        }
    }
}
