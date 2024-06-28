//
//  SettingsView.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/6/24.
//

import Foundation

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userPreferences: UserPreferences

    var body: some View {
            List {
                Section(header: Text("General")) {
                 
                }
                ColorPicker("Accent Color", selection: $userPreferences.accentColor)

            }
            .navigationTitle("Settings")
        }
}
