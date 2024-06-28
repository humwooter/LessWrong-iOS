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
    @State private var isLoading = false
    @State private var pageTitle = ""
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            HStack {
                if canGoBack {
                    Button(action: {
                        NotificationCenter.default.post(name: Notification.Name("goBack"), object: nil)
                    }) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                }
                Text(pageTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                if isLoading {
                    ProgressView()
                        .padding()
                }
            }
            WebViewContainer(content: nil, url: URL(string: postURL), backgroundColor: .black)
        }
        .padding()
        .navigationTitle("Post Detail")
        .background {
            ZStack {
                LinearGradient(colors: [getTopBackgroundColor(colorScheme: colorScheme), getBackgroundColor(colorScheme: colorScheme)], startPoint: .top, endPoint: .bottom)
            }.ignoresSafeArea(.all)
        }
        .task {
            await networkManager.fetchPostDetail(url: postURL)
        }
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
