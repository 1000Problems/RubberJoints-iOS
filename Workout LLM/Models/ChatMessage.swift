import Foundation
import SwiftData

@Model
final class ChatMessage {
    var role: String                 // "user", "assistant", "system"
    var content: String
    var timestamp: Date = Date()

    init(role: String, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }

    var isUser: Bool { role == "user" }
    var isAssistant: Bool { role == "assistant" }
}
