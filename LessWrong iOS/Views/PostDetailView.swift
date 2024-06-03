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
    let post: Post
    @EnvironmentObject var networkManager: NetworkManager
    @State private var canGoBack = false

    var body: some View {
        detailView()
            .padding()
            .navigationTitle("Post Detail")
            .background {
                ZStack {
                    LinearGradient(colors: [Color.clear, Color.brown.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                }.ignoresSafeArea()
            }
            .onAppear {
                networkManager.fetchPostDetail(url: post.url)
            }
    }

    @ViewBuilder
    func detailView() -> some View {
        if let url = URL(string: post.url) {
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
