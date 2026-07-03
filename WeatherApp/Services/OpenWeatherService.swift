import Foundation

/// Network layer for OpenWeatherMap weather and geocoding endpoints.
final class OpenWeatherService: WeatherServiceProtocol, GeocodingServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let apiKey: String?

    init(session: URLSession = OpenWeatherConfiguration.makeURLSession(), apiKey: String? = nil) {
        self.session = session
        self.apiKey = apiKey
    }

    private var resolvedAPIKey: String {
        apiKey ?? OpenWeatherConfiguration.apiKey
    }

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
        guard !resolvedAPIKey.isEmpty else { throw WeatherError.missingAPIKey }

        var components = URLComponents(url: OpenWeatherConfiguration.weatherBaseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: resolvedAPIKey),
            URLQueryItem(name: "units", value: "imperial")
        ]

        return try await performWeatherRequest(url: components?.url)
    }

    func fetchWeather(city: String, state: String?, country: String) async throws -> WeatherResponse {
        let location = try await geocode(city: city, state: state, country: country)
        return try await fetchWeather(latitude: location.lat, longitude: location.lon)
    }

    func geocode(city: String, state: String?, country: String) async throws -> GeocodingResult {
        guard !resolvedAPIKey.isEmpty else { throw WeatherError.missingAPIKey }

        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCity.isEmpty else { throw WeatherError.emptySearchQuery }

        var query = trimmedCity
        if let state, !state.isEmpty {
            query += ",\(state)"
        }
        query += ",\(country)"

        var components = URLComponents(url: OpenWeatherConfiguration.geocodingBaseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "1"),
            URLQueryItem(name: "appid", value: resolvedAPIKey)
        ]

        guard let url = components?.url else { throw WeatherError.invalidResponse }

        let (data, response) = try await session.data(from: url)
        try validateHTTPResponse(response)

        let results = try JSONDecoder().decode([GeocodingResult].self, from: data)
        guard let first = results.first else { throw WeatherError.cityNotFound }
        return first
    }

    private func performWeatherRequest(url: URL?) async throws -> WeatherResponse {
        guard let url else { throw WeatherError.invalidResponse }

        do {
            let (data, response) = try await session.data(from: url)
            try validateHTTPResponse(response)
            return try JSONDecoder().decode(WeatherResponse.self, from: data)
        } catch let error as WeatherError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw WeatherError.networkUnavailable
        } catch {
            throw WeatherError.invalidResponse
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            return
        case 404:
            throw WeatherError.cityNotFound
        case 401, 403:
            throw WeatherError.missingAPIKey
        default:
            throw WeatherError.serverMessage(String(localized: "Weather service returned an error (\(http.statusCode))."))
        }
    }
}
