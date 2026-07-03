import Foundation

protocol WeatherServiceProtocol: Sendable {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse
    func fetchWeather(city: String, state: String?, country: String) async throws -> WeatherResponse
}

protocol GeocodingServiceProtocol: Sendable {
    func geocode(city: String, state: String?, country: String) async throws -> GeocodingResult
}

protocol SearchHistoryStorageProtocol: Sendable {
    func saveLastSearchedCity(_ city: String)
    func lastSearchedCity() -> String?
}

protocol ImageCacheServiceProtocol: Sendable {
    func image(for url: URL) async throws -> Data
    func clearCache()
}

protocol LocationServiceProtocol: AnyObject {
    var authorizationStatus: LocationAuthorizationStatus { get }
    func requestAuthorization()
    func requestCurrentLocation() async throws -> (latitude: Double, longitude: Double)
}

enum LocationAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}
