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
                    ColorPicker("Accent Color", selection: $userPreferences.accentColor)
                    Toggle("Show EA Forum", isOn: $userPreferences.showEAForum)
                    HStack {
                        Text("Post Fetch Count")
                        Slider(value: $userPreferences.newPostsCount, in: 5...30, step: 1) {
                            Text("Post Fetch Count")
                        }
                        .padding(.leading)
                    }
                    Text("Fetch count: \(Int(userPreferences.newPostsCount))")
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
}
