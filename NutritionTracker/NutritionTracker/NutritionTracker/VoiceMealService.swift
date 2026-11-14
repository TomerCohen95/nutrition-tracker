import Foundation

struct VoiceMealAnalysis: Decodable {
    let transcript: String
    let clarification: String?
    let items: [Item]

    struct Item: Decodable {
        let name: String
        let calories: Double?
        let protein: Double?
        let status: String
        let date: String
        let source: String?
        let historySource: String?
        let personalSource: String?
        let estimateSource: String?
    }
}

struct VoiceMealService {
    let endpoint: String

    struct SavedFood: Encodable, Hashable {
        let name: String
        let calories: Int
        let protein: Int?
    }

    private struct Payload: Encodable {
        let content: Data
        let isRecording: Bool
        let history: [SavedFood]
        let personalFoods: [PersonalFood]
    }

    func analyze(_ content: Data, isRecording: Bool, date: Date, history: [SavedFood], personalFoods: [PersonalFood]) async throws -> VoiceMealAnalysis {
        guard let components = URLComponents(string: endpoint.trimmingCharacters(in: .whitespacesAndNewlines)),
              components.scheme == "https", components.host?.hasSuffix(".ts.net") == true,
              components.user == nil, components.password == nil, components.query == nil,
              components.fragment == nil, let baseURL = components.url else {
            throw Error.message("Enter your Tailscale Serve HTTPS address.")
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("v2/meal"), timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.dayString(Date()), forHTTPHeaderField: "X-Meal-Today")
        request.setValue(Self.dayString(date), forHTTPHeaderField: "X-Meal-Date")
        request.httpBody = try JSONEncoder().encode(Payload(content: content, isRecording: isRecording, history: history, personalFoods: personalFoods))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let problem = try? JSONDecoder().decode(Problem.self, from: data)
            throw Error.message(problem?.error ?? "The voice service is unavailable. Check Tailscale and try again.")
        }
        return try JSONDecoder().decode(VoiceMealAnalysis.self, from: data)
    }

    static func dayString(_ date: Date) -> String {
        formatter().string(from: date)
    }

    static func date(_ day: String) -> Date? {
        formatter().date(from: day)
    }

    private static func formatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private struct Problem: Decodable {
        let error: String
    }

    enum Error: LocalizedError {
        case message(String)

        var errorDescription: String? {
            switch self {
            case .message(let text): text
            }
        }
    }
}
