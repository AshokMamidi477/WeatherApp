import Foundation

/// Domain errors surfaced to the user with friendly copy.
enum WeatherError: LocalizedError, Equatable {
    case emptySearchQuery
    case invalidCity
    case cityNotFound
    case locationDenied
    case locationUnavailable
    case networkUnavailable
    case invalidResponse
    case missingAPIKey
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .emptySearchQuery:
            return String(localized: "Please enter a US city name.")
        case .invalidCity:
            return String(localized: "Enter a valid US city name.")
        case .cityNotFound:
            return String(localized: "We couldn't find that city. Try another US city.")
        case .locationDenied:
            return String(localized: "Location access is off. You can still search for a city.")
        case .locationUnavailable:
            return String(localized: "Your current location isn't available right now.")
        case .networkUnavailable:
            return String(localized: "Check your internet connection and try again.")
        case .invalidResponse:
            return String(localized: "We received an unexpected response. Please try again.")
        case .missingAPIKey:
            return String(localized: "Weather service is not configured. Add your OpenWeather API key.")
        case .serverMessage(let message):
            return message
        }
    }
}
