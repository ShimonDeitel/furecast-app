import Foundation

enum AIProxyError: Error {
    case badURL
    case network(Error)
    case badHTTPStatus(Int)
    case decodeFailure
}

/// Thin client for the shared, no-key AI proxy (see pulse/ANIMATED_TEN_QUEUE.md). No secret is
/// embedded — the proxy is stateless and keyless from the app's point of view, rate-limited
/// server-side per IP instead.
struct AIProxyClient {
    static let baseURL = "https://apps-ai-proxy.s0533495227.workers.dev"

    private struct ChatChoice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    private struct ChatResponse: Decodable {
        let choices: [ChatChoice]
    }

    /// POSTs a plain text request (breed + age + logged-expense summary) and returns the
    /// model's raw plain-text reply for `AICoach.parse` to interpret.
    func complete(systemPrompt: String, userPrompt: String) async throws -> String {
        guard let url = URL(string: "\(Self.baseURL)/text") else { throw AIProxyError.badURL }

        let body: [String: Any] = [
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 45

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIProxyError.network(error)
        }

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw AIProxyError.badHTTPStatus(status)
        }

        guard let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data),
              let content = decoded.choices.first?.message.content,
              !content.isEmpty else {
            throw AIProxyError.decodeFailure
        }

        return content
    }
}

extension AIProxyError {
    /// Always a plain, non-technical message so a briefly-unavailable proxy never surfaces a
    /// crash or a raw error code to the owner.
    var userMessage: String {
        switch self {
        case .badURL, .decodeFailure:
            return "Furecast couldn't read the AI coach's reply. Try again in a moment."
        case .network:
            return "Couldn't reach the AI coach right now — check your connection and try again."
        case .badHTTPStatus:
            return "The AI coach is briefly unavailable. Try again shortly."
        }
    }
}

/// One AI-flagged surprise-cost risk to watch for, as returned by the coaching prompt.
struct AIRiskInsight: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let range: String
    let why: String
}

struct AICoachingResult: Hashable {
    let risks: [AIRiskInsight]
    let tip: String
}

/// Builds the coaching prompt and parses the model's JSON-in-a-string reply. Parsing is pure
/// and testable independent of the network call itself.
enum AICoach {
    static func systemPrompt() -> String {
        """
        You are a plain-spoken veterinary cost-planning assistant inside the Furecast app. \
        Given a pet's species, breed, age, and a summary of expenses logged so far, identify \
        2 to 3 specific breed-linked "surprise cost" risks the owner should watch for, each \
        with a rough first-year dollar range, plus exactly one practical money-saving tip \
        tailored to the logged spending pattern. Respond with ONLY compact JSON, no prose \
        outside the JSON, in this exact shape: \
        {"risks":[{"title":string,"range":string,"why":string}],"tip":string}
        """
    }

    static func userPrompt(species: String, breed: String, ageDescription: String, expenseSummary: String) -> String {
        """
        Species: \(species)
        Breed: \(breed)
        Age: \(ageDescription)
        Logged expenses so far: \(expenseSummary)
        """
    }

    private struct RawRisk: Decodable {
        let title: String
        let range: String
        let why: String
    }
    private struct RawResult: Decodable {
        let risks: [RawRisk]
        let tip: String
    }

    /// Extracts the first `{...}` JSON object found in `content` (models sometimes wrap JSON
    /// in a sentence or code fence despite instructions) and decodes it. Returns nil — never
    /// throws — so the caller can fall back to showing the raw text gracefully.
    static func parse(_ content: String) -> AICoachingResult? {
        guard let first = content.firstIndex(of: "{"), let last = content.lastIndex(of: "}"), first < last else {
            return nil
        }
        let jsonSlice = content[first...last]
        guard let data = jsonSlice.data(using: .utf8),
              let raw = try? JSONDecoder().decode(RawResult.self, from: data) else {
            return nil
        }
        let risks = raw.risks.map { AIRiskInsight(title: $0.title, range: $0.range, why: $0.why) }
        return AICoachingResult(risks: risks, tip: raw.tip)
    }
}
