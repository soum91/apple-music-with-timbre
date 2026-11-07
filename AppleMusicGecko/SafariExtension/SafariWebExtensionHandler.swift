import Foundation
import SafariServices

// Required Safari extension entry point. All equalization happens locally in
// Safari's web content; the native handler does not receive audio or tokens.
final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: ["ready": true]]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
