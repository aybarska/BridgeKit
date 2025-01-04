import Foundation
import WebKit

public protocol JavaScriptEvaluation {
    func evaluateJavaScript(
        _ javaScriptString: String,
        completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)?
    )
}

extension WKWebView: JavaScriptEvaluation {}

private extension Encodable {
    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    func jsonObject() throws -> Any {
        return try jsonData().jsonObject()
    }
}

private extension Data {
    func jsonObject() throws -> Any {
        return try JSONSerialization.jsonObject(with: self, options: [])
    }

    func jsonString() throws -> String {
        guard let jsonString = String(data: self, encoding: .utf8) else {
            throw BridgeKitCore.BridgeError.encodingError(message: "Could not convert data to UTF-8 string")
        }
        return jsonString
    }
}

private extension Decodable {
    static func from(jsonObject: Any) -> Self? {
        guard let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
              let decodedValue = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }
        return decodedValue
    }
}

public protocol Topic {
    var name: String { get }
}

struct AnyTopic: Topic {
    let name: String
}

public final class BridgeKitCore {
    private let webView: JavaScriptEvaluation
    private var messageHandlers: [String: (Data, BridgeKitCore) -> Void] = [:]

    public init(webView: JavaScriptEvaluation) {
        self.webView = webView
    }
}

extension BridgeKitCore {

    public enum BridgeError: Error, LocalizedError {
        case illegalPayloadFormat(message: String)
        case missingField(key: String)
        case missingMessageHandler(topic: String)
        case invalidDataForHandler(topic: String, expectedType: String)
        case encodingError(message: String)

        public var errorDescription: String? {
            switch self {
            case .illegalPayloadFormat(let message):
                return message
            case .missingField(let key):
                return "Missing field: \(key)"
            case .missingMessageHandler(let topic):
                return "Missing message handler for topic: \(topic)"
            case .invalidDataForHandler(let topic, let expectedType):
                return "Invalid data for topic '\(topic)'. Expected type: '\(expectedType)'"
            case .encodingError(let message):
                return message
            }
        }

        var errorCode: Int { // This part remains the same
            switch self {
            case .illegalPayloadFormat: return 1
            case .missingField: return 2
            case .missingMessageHandler: return 3
            case .invalidDataForHandler: return 4
            case .encodingError: return 5
            }
        }
    }
    
    private struct ErrorResponse: Codable {
        let errors: [ErrorDetail]
    }

    private struct ErrorDetail: Codable {
        let message: String
        let errorCode: Int
    }

    public enum BridgeResponse {
        case success(Any?)
        case failure(BridgeError)
    }

    /// Sends a message to the JavaScript side.
    public func postMessage<T: Codable>(data: T, to topic: Topic, completion: ((BridgeResponse) -> Void)? = nil) {
        do {
            let jsonData = try data.jsonData() // Convert to Data here
            postMessage(data: jsonData, to: topic.name, completion: completion)
        } catch {
            completion?(.failure(.encodingError(message: error.localizedDescription)))
        }
    }

    private func postMessage(data: Data, to topic: String, completion: ((BridgeResponse) -> Void)? = nil) {
        do {
            let jsonObject = try data.jsonObject()
            let payload: [String: Any] = ["topic": topic, "data": jsonObject]
            var payloadString = ""
            if #available(iOS 11.0, *) {
                payloadString = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]).jsonString()
            } else {
                payloadString = try JSONSerialization.data(withJSONObject: payload).jsonString()
            }
            postMessage(json: payloadString, completion: completion)
        } catch {
            completion?(.failure(.encodingError(message: error.localizedDescription)))
        }
    }

    private func postMessage(json: String, completion: ((BridgeResponse) -> Void)? = nil) {
        let js = "window.dispatchEvent(new CustomEvent('bridgekit', {detail: \(json)}));"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                completion?(.failure(.encodingError(message: error.localizedDescription)))
            } else {
                completion?(.success(result))
            }
        }
    }
    
    private func sendErrorResponse(errors: [BridgeError], forTopic topic: String? = nil) {
        let errorDetails = errors.map { ErrorDetail(message: $0.errorDescription ?? "", errorCode: $0.errorCode) }
        let errorResponse = ErrorResponse(errors: errorDetails)

//        self.postMessage(data: errorResponse, to: topic ?? "error")
        let errorTopic = topic != nil ? AnyTopic(name: topic!) : AnyTopic(name: "error")
        postMessage(data: errorResponse, to: errorTopic)
    }
    
    /// Registers a handler for incoming messages from JavaScript.
    public func registerMessageHandler<T: Codable>(for topic: Topic, handler: @escaping (T, BridgeKitCore) -> Void) {
        messageHandlers[topic.name] = { [weak self] data, bridge in
            guard let self = self else { return }
            guard let decodedData = T.from(jsonObject: try! data.jsonObject()) else { // Force-unwrap is safe here because we check for jsonObject earlier in the process.
                self.sendErrorResponse(errors: [.invalidDataForHandler(topic: topic.name, expectedType: String(describing: T.self))], forTopic: topic.name)
                return
            }
            handler(decodedData, bridge)
        }
    }

    /// Handles incoming messages from the JavaScript side. This should be called from your WKScriptMessageHandler's userContentController(_:didReceive:) method.
    public func handleReceivedMessage(_ message: Any) {
        guard let payload = message as? [String: Any] else {
            sendErrorResponse(errors: [.illegalPayloadFormat(message: "Payload is not a dictionary")])
            return
        }

        guard let topic = payload["topic"] as? String else {
            sendErrorResponse(errors: [.missingField(key: "topic")])
            return
        }

        guard let data = payload["data"] else {
            sendErrorResponse(errors: [.missingField(key: "data")])
            return
        }

        guard let handler = messageHandlers[topic] else {
            sendErrorResponse(errors: [.missingMessageHandler(topic: topic)])
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            handler(jsonData, self)
        } catch {
            sendErrorResponse(errors: [.encodingError(message: "Could not serialize data")])
        }
    }
}
