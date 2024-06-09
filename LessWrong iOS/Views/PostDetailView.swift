//
//  PostDetailView.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/3/24.
//

import Foundation
import SwiftUI
import WebKit
import UIKit


struct PostDetailView: View {
    let postURL: String
    @EnvironmentObject var networkManager: NetworkManager
    @State private var canGoBack = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        detailView()
            .padding()
            .navigationTitle("Post Detail")
            .background {
                ZStack {
                    LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme),getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
                }.ignoresSafeArea(.all)
            }
            .task {
                       await networkManager.fetchPostDetail(url: postURL)
                   }
    }

    @ViewBuilder
    func detailView() -> some View {
        if let url = URL(string: postURL) {
            VStack {
                if canGoBack {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                }
                WebView(url: url, backgroundColor: .black, canGoBack: $canGoBack)
            }
        } else {
            Text("Invalid URL")
                .foregroundColor(.red)
        }
    }

    private func goBack() {
        NotificationCenter.default.post(name: Notification.Name("goBack"), object: nil)
    }

    func formattedDate(from dateString: String?) -> String {
        guard let dateString = dateString else { return "N/A" }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            return DateFormatter.postDateFormatter.string(from: date)
        }
        return dateString
    }
}
