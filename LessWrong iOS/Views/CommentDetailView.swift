//
//  CommentDetailView.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/4/24.
//

import Foundation
import SwiftUI
import WebKit
import UIKit

struct CommentDetailView: View {
    let comment: Comment
    @EnvironmentObject var networkManager: NetworkManager
    @State private var canGoBack = false

    var body: some View {
        detailView()
            .padding()
            .navigationTitle("Comment Detail")
            .background {
                ZStack {
                    LinearGradient(colors: [Color.clear, Color.blue.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                }.ignoresSafeArea()
            }
    }

    @ViewBuilder
    func detailView() -> some View {
        VStack {
            if canGoBack {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .padding()
                }
            }
            Text(comment.contents)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
            HStack {
                Text("Author: \(comment.user.slug ?? "Unknown")")
                Spacer()
//                Text("Date: \(formattedDate(from: comment.date))")
            }
            .padding()
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
