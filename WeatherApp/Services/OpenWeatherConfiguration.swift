import Foundation

enum OpenWeatherConfiguration {
    static var apiKey: String {
        let candidates = [
            ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"],
            Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String
        ]

        for candidate in candidates {
            guard let rawKey = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            guard isValidKey(rawKey) else { continue }
            return rawKey
        }

        return ""
    }

    static let weatherBaseURL = URL(string: "https://api.openweathermap.org/data/2.5/weather")!
    static let geocodingBaseURL = URL(string: "https://api.openweathermap.org/geo/1.0/direct")!

    static func makeURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }

    private static func isValidKey(_ key: String) -> Bool {
        !key.isEmpty && key != "YOUR_API_KEY_HERE" && !key.hasPrefix("$(")
    }
}
