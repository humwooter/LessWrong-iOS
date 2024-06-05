//
//  ShareSheet.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/4/24.
//

import Foundation
import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update currently needed
    }
}
