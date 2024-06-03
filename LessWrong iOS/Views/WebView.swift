//
//  WebView.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/3/24.
//
import Foundation
import WebKit
import UIKit
import SwiftUI

import Foundation
import WebKit
import UIKit
import SwiftUI

struct WebView: UIViewRepresentable {
    let content: String?
    let url: URL?
    let backgroundColor: UIColor
    @Binding var canGoBack: Bool
    
    init(content: String? = nil, url: URL? = nil, backgroundColor: UIColor = .white, canGoBack: Binding<Bool>) {
        self.content = content
        self.url = url
        self.backgroundColor = backgroundColor
        self._canGoBack = canGoBack
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        let progressView = UIProgressView(progressViewStyle: .default)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(webView)
        containerView.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            progressView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
        
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.customUserAgent = "CustomUserAgent/1.0"
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        context.coordinator.webView = webView
        context.coordinator.progressView = progressView
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let webView = context.coordinator.webView {
            webView.backgroundColor = backgroundColor
            if let content = content {
                webView.loadHTMLString(content, baseURL: nil)
            } else if let url = url {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }
    
    func makeConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        configuration.allowsInlineMediaPlayback = true
        
        let userScript = WKUserScript(source: "document.body.style.backgroundColor = 'lightgray';", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        
        return configuration
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView
        weak var webView: WKWebView?
        weak var progressView: UIProgressView?
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("Failed to load: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Navigation finished")
            updateCanGoBack(webView)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "estimatedProgress" {
                if let webView = object as? WKWebView {
                    progressView?.progress = Float(webView.estimatedProgress)
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let errorHTML = """
            <html>
            <body>
            <h1>Oops!</h1>
            <p>Something went wrong.</p>
            <p>\(error.localizedDescription)</p>
            </body>
            </html>
            """
            webView.loadHTMLString(errorHTML, baseURL: nil)
        }
        
        func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
            let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                let openAction = UIAction(title: "Open", image: UIImage(systemName: "link")) { _ in
                    if let url = elementInfo.linkURL {
                        UIApplication.shared.open(url)
                    }
                }
                return UIMenu(title: "", children: [openAction])
            }
            completionHandler(config)
        }
        
        func updateCanGoBack(_ webView: WKWebView) {
            DispatchQueue.main.async {
                self.parent.canGoBack = webView.canGoBack
            }
        }
    }
}

struct WebViewContainer: View {
    @State private var canGoBack = false
    let content: String?
    let url: URL?
    let backgroundColor: UIColor

    var body: some View {
        VStack {
            HStack {
                if canGoBack {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                }
                Spacer()
            }
            WebView(content: content, url: url, backgroundColor: backgroundColor, canGoBack: $canGoBack)
        }
    }

    private func goBack() {
        // Send notification to WebView to go back
        NotificationCenter.default.post(name: Notification.Name("goBack"), object: nil)
    }
}

