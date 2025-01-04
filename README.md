![Logo](ss/BridgeKit.png)
# BridgeKit for Swift - Simplifying Communication Between Your App and Webviews

[![CI Status](https://img.shields.io/travis/aybarska/BridgeKit.svg?style=flat)](https://travis-ci.org/aybarska/BridgeKit)
[![Version](https://img.shields.io/cocoapods/v/BridgeKit.svg?style=flat)](https://cocoapods.org/pods/BridgeKit)
[![License](https://img.shields.io/cocoapods/l/BridgeKit.svg?style=flat)](https://cocoapods.org/pods/BridgeKit)
[![Platform](https://img.shields.io/cocoapods/p/BridgeKit.svg?style=flat)](https://cocoapods.org/pods/BridgeKit)

**What is BridgeKit?**

BridgeKit is a lightweight Swift library designed to simplify communication between your native iOS app and JavaScript code running within a `WKWebView`. It provides a clean and intuitive API for sending and receiving messages, enabling seamless interaction between your native and web content.

**Why use BridgeKit?**

*   **Simplified Message Handling:** BridgeKit abstracts away the complexities of `WKWebView` communication, providing a streamlined approach to sending and receiving messages.
*   **Flexible Data Exchange:** Send and receive complex data structures (using `Codable` objects) between your app and the webview.
*   **Improved Maintainability:** Separate message handling logic from your view code for better organization and easier maintenance.

**Installation:**

BridgeKit is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your `Podfile`:

```ruby
pod 'BridgeKit'
```
Then, run pod install or pod update in your terminal.

**Usage:**

1.  **Import:** Import BridgeKit in your view controller:

    ```swift
    import BridgeKit
    ```

2.  **Initialize BridgeKit and Configure WKWebView:** In your view controller (typically in `viewDidLoad()`), create a `WKWebView`, configure its `WKUserContentController`, and initialize an instance of `BridgeKitCore`:

    ```swift
    import UIKit
    import WebKit
    import BridgeKit

    class ViewController: UIViewController, WKScriptMessageHandler {
        private var webView: WKWebView!
        private var bridge: BridgeKitCore!

        override func viewDidLoad() {
            super.viewDidLoad()

            let contentController = WKUserContentController()
            contentController.add(self, name: "bridgekit") // Important: Must match JS name

            let config = WKWebViewConfiguration()
            config.userContentController = contentController

            webView = WKWebView(frame: .zero, configuration: config)
            view.addSubview(webView) // Add webview to your view hierarchy

            bridge = BridgeKitCore(webView: webView)

            registerHandlers() // Register message handlers
            loadWebViewContent() // Load your web content
            setupUI() // Set up your UI (if needed)
        }
        // ...
    }
    ```

3.  **Register Message Handlers (Swift):** Define message handlers in your Swift code to respond to messages from JavaScript. Use structs conforming to the `Topic` protocol to define message topics, and `Codable` structs to define the data being sent. It's crucial to match the data structure with the one from js:

    ```swift
    private func registerHandlers() {
        // Handle "showAlert" message
        struct ShowAlertTopic: Topic {
            let name: String = "showAlert"
        }

        struct EmptyData: Codable {} // Data type for showAlert (no data)

        bridge.registerMessageHandler(for: ShowAlertTopic()) { [weak self] (_: EmptyData, bridge) in
            DispatchQueue.main.async { // Ensure UI updates on main thread
                let alert = UIAlertController(title: "Native Alert", message: "Button pressed in webview!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }

        // Handle "myTopic" message with string data
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
    ```

4.  **Send Messages from Swift:** Use `bridge.postMessage` to send messages to your JavaScript code. Provide the data (as a `Codable` struct) and the topic (as a struct conforming to the `Topic` protocol):

    ```swift
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
    ```

5.  **JavaScript Code (index.html):** In your web page, use `window.webkit.messageHandlers.bridgekit.postMessage` to send messages to Swift. The `topic` and the structure of the `data` object must match the Swift `Topic` and `Codable` structs:

    ```html
    <!DOCTYPE html>
    <html>
    <head>
        <title>BridgeKit Example</title>
        <style>
            body { font-size: 20px; padding: 20px;}
            button { font-size: 20px; padding: 10px 20px;}
            #receivedText {
                font-size: 30px;
                color: red;
                text-align: center;
                margin-top: 20px;
                font-weight: bold;
                padding: 10px;
                border: 2px solid red;
            }
            #responseFromNative {
                margin-top: 10px;
            }
        </style>
    </head>
    <body>
        <div id="receivedText"></div>
        <button onclick="showAlert()">Show Native Alert</button><br><br>
        <input type="text" id="webInput" placeholder="Enter text here"><br><br>
        <button onclick="sendMessage()">Send Message to Native</button>
        <div id="responseFromNative"></div>
        <script>
            function sendMessage() {
                const message = { receivedText: "Hello from JavaScript!" }; // Match Swift struct
                window.webkit.messageHandlers.bridgekit.postMessage({ topic: "myTopic", data: message }); // Match Swift Topic name
            }

            function showAlert() {
                window.webkit.messageHandlers.bridgekit.postMessage({ topic: "showAlert", data: {} }); // Empty data for alert
            }

            window.addEventListener('bridgekit', function(event) {
                if (event.detail && event.detail.topic === "textFromNative") {
                    const receivedText = event.detail.data.text;
                    document.getElementById('receivedText').innerText = "Hello " + receivedText;
                }
                if (event.detail && event.detail.topic === "myTopicResponse") {
                    document.getElementById('responseFromNative').innerText = event.detail.data.response;
                  }
        });
    </script>
    </body>
    </html>
    ```

## Conclusion:

BridgeKit empowers you to seamlessly bridge the gap between your native app and webview content. With its intuitive API and robust features, it streamlines message handling, simplifies data exchange, and ultimately enhances your app's development experience.

## Author

Ayberk Mogol, ayberk.m@yandex.com

## License

BridgeKit is available under the MIT license. See the LICENSE file for more info.
