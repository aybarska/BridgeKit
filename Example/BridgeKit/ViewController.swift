//
//  ViewController.swift
//  BridgeKit
//
//  Created by Ayberk Mogol on 01/02/2025.
//  Copyright (c) 2025 Ayberk Mogol. All rights reserved.
//
import UIKit
import WebKit
import BridgeKit

class ViewController: UIViewController, WKScriptMessageHandler {

    private var webViewTopLabel: UILabel!
    private var webView: WKWebView!
    private var bridge: BridgeKit!
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white // Set background color for better visibility

        // 1. Configure WKWebView
        let contentController = WKUserContentController()
        contentController.add(self, name: "bridgekit")
        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false // Enable Auto Layout
        webView.layer.borderColor = UIColor.systemGray.cgColor
        webView.layer.borderWidth = 1
        view.addSubview(webView)

        // 2. Initialize BridgeKit
        bridge = BridgeKit(webView: webView)

        // 3. Register Message Handlers
        registerHandlers()

        // 4. Load Web Content
        loadWebViewContent()

        // UI Setup
        setupUI()
    }

    private func setupUI() {
        
        webViewTopLabel = UILabel()
        webViewTopLabel.translatesAutoresizingMaskIntoConstraints = false
        webViewTopLabel.text = "WEB VIEW"
        webViewTopLabel.font = .systemFont(ofSize: 16, weight: .bold)
        webViewTopLabel.textColor = .black
        webViewTopLabel.textAlignment = .center
        view.addSubview(webViewTopLabel)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter text here"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        view.addSubview(textField)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("Send to Web", for: .normal)
        sendButton.addTarget(self, action: #selector(sendTextToWeb), for: .touchUpInside)
        view.addSubview(sendButton)

        let padding: CGFloat = 20

        NSLayoutConstraint.activate([
             // Label constraints (Corrected)
             webViewTopLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
             webViewTopLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
             webViewTopLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
             webViewTopLabel.heightAnchor.constraint(equalToConstant: 30),

             // WebView constraints (Corrected)
             webView.topAnchor.constraint(equalTo: webViewTopLabel.bottomAnchor, constant: 4),
             webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
             webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
             webView.bottomAnchor.constraint(equalTo: textField.topAnchor, constant: -padding),

             // TextField constraints
             textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
             textField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),

             // SendButton constraints
             sendButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: padding),
             sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding)
         ])
    }

    @objc private func sendTextToWeb() {
        guard let text = textField.text, !text.isEmpty else { return }

        struct TextData: Codable {
            let text: String
        }

        struct TextTopic: Topic {
            let name: String = "textFromNative"
        }

        bridge.postMessage(data: TextData(text: text), to: TextTopic()) { response in
            switch response {
            case .success:
                print("Text sent to web successfully")
            case .failure(let error):
                print("Error sending text to web: \(error)")
            }
        }
    }

    private func registerHandlers() {
        
        // FOR ALERT
        struct ShowAlertTopic: Topic {
            let name: String = "showAlert"
        }

        bridge.registerMessageHandler(for: ShowAlertTopic()) { [weak self] (_: EmptyData, bridge) in
            DispatchQueue.main.async { // Important: Update UI on main thread
                let alert = UIAlertController(title: "Native Alert", message: "Button pressed in webview!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }

      // FOR MESSAGE
      struct ResponseData: Codable {
          let receivedText: String
      }

      struct ResponseTopic: Topic {
        let name: String = "myTopic"
      }
        
      bridge.registerMessageHandler(for: ResponseTopic()) { (data: ResponseData, bridge) in
        print("Received response from web: \(data.receivedText)")
      }
        
    }

    private func loadWebViewContent() {
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>BridgeKit Test</title>
            <style>
                body { font-size: 42px; padding: 20px;}
                button { font-size: 42px; padding: 10px 20px;}
            </style>
        </head>
        <body>
            <h1>BridgeKit Test</h1>
            <div id="receivedText" style="font-size: 42px; color: red; text-align: center; margin-top: 20px;"></div>
            <br>
            <button onclick="showAlert()">Show Native Alert</button><br><br>
            <button onclick="sendMessage()">Send Message to Native(See in console)</button>
            <script>
        
                function sendMessage() {
                    const message = { receivedText: "Hello from JavaScript!" };
                    window.webkit.messageHandlers.bridgekit.postMessage({ topic: "myTopic", data: message });
                }

                function showAlert() {
                    window.webkit.messageHandlers.bridgekit.postMessage({ topic: "showAlert", data: {} });
                }

                window.addEventListener('bridgekit', function(event) {
                    if (event.detail.topic === "textFromNative") {
                        const receivedText = event.detail.data.text;
                        document.getElementById('receivedText').innerText = "Hello " + receivedText;
                    }
                });
        
            </script>

        </body>
        </html>
        """
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }

    // WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "bridgekit" {
            bridge.handleReceivedMessage(message.body)
        }
    }
}

struct AnyTopic: Topic {
    let name: String
}

struct EmptyData: Codable {} // Define EmptyData
