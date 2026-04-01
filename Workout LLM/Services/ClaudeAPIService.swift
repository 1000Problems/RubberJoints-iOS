import Foundation

/// Lightweight Claude Messages API client — no external dependencies.
actor ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-20250514"

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct APIRequest: Codable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]
    }

    struct ContentBlock: Codable {
        let type: String
        let text: String?
    }

    struct APIResponse: Codable {
        let content: [ContentBlock]
    }

    struct APIError: Codable {
        let error: ErrorDetail?
        struct ErrorDetail: Codable {
            let message: String
        }
    }

    enum ServiceError: LocalizedError {
        case noAPIKey
        case httpError(Int, String)
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No API key configured. Add your Anthropic key in Settings."
            case .httpError(let code, let message):
                return "API error (\(code)): \(message)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }

    /// Send a conversation to Claude and get a response.
    /// - Parameters:
    ///   - messages: The conversation history (role: "user" or "assistant")
    ///   - systemPrompt: The system prompt with user context
    /// - Returns: The assistant's reply text
    func sendMessage(messages: [Message], systemPrompt: String) async throws -> String {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            throw ServiceError.noAPIKey
        }

        let body = APIRequest(
            model: model,
            max_tokens: 1024,
            system: systemPrompt,
            messages: messages
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ServiceError.networkError(error)
        }

        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0

        guard statusCode == 200 else {
            let errorBody = try? JSONDecoder().decode(APIError.self, from: data)
            let message = errorBody?.error?.message ?? "Unknown error"
            throw ServiceError.httpError(statusCode, message)
        }

        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        return apiResponse.content.compactMap(\.text).joined()
    }
}
