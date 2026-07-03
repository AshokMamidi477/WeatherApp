import Foundation
@testable import WeatherApp

final class MockWeatherService: WeatherServiceProtocol, @unchecked Sendable {
    var weatherByCoordinatesResult: Result<WeatherResponse, Error> = .failure(WeatherError.invalidResponse)
    var weatherByCityResult: Result<WeatherResponse, Error> = .failure(WeatherError.invalidResponse)
    var fetchWeatherByCoordinatesCalls: [(Double, Double)] = []
    var fetchWeatherByCityCalls: [(String, String?, String)] = []

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
        fetchWeatherByCoordinatesCalls.append((latitude, longitude))
        return try weatherByCoordinatesResult.get()
    }

    func fetchWeather(city: String, state: String?, country: String) async throws -> WeatherResponse {
        fetchWeatherByCityCalls.append((city, state, country))
        return try weatherByCityResult.get()
    }
}

final class MockGeocodingService: GeocodingServiceProtocol, @unchecked Sendable {
    var geocodeResult: Result<GeocodingResult, Error> = .failure(WeatherError.cityNotFound)
    var geocodeCalls: [(String, String?, String)] = []

    func geocode(city: String, state: String?, country: String) async throws -> GeocodingResult {
        geocodeCalls.append((city, state, country))
        return try geocodeResult.get()
    }
}

final class MockSearchHistoryStorage: SearchHistoryStorageProtocol, @unchecked Sendable {
    private(set) var savedCities: [String] = []
    var storedCity: String?

    func saveLastSearchedCity(_ city: String) {
        savedCities.append(city)
        storedCity = city
    }

    func lastSearchedCity() -> String? {
        storedCity
    }
}

final class MockImageCacheService: ImageCacheServiceProtocol, @unchecked Sendable {
    var imageResult: Result<Data, Error> = .success(Data([0x01]))
    var requestedURLs: [URL] = []

    func image(for url: URL) async throws -> Data {
        requestedURLs.append(url)
        return try imageResult.get()
    }

    func clearCache() {}
}

final class MockLocationService: LocationServiceProtocol {
    var authorizationStatus: LocationAuthorizationStatus = .notDetermined
    var currentLocationResult: Result<(latitude: Double, longitude: Double), Error> =
        .success((30.2672, -97.7431))

    func requestAuthorization() {}

    func requestCurrentLocation() async throws -> (latitude: Double, longitude: Double) {
        try currentLocationResult.get()
    }
}

enum WeatherFixture {
    static let austinResponse = WeatherResponse(
        name: "Austin",
        main: .init(temp: 82, feelsLike: 85, humidity: 55, tempMin: 70, tempMax: 90),
        weather: [.init(id: 800, main: "Clear", description: "clear sky", icon: "01d")],
        wind: .init(speed: 8),
        sys: .init(country: "US")
    )
}

extension DependencyContainer {
    static func mock(
        weatherService: WeatherServiceProtocol,
        geocodingService: GeocodingServiceProtocol? = nil,
        searchHistoryStorage: SearchHistoryStorageProtocol = MockSearchHistoryStorage(),
        imageCacheService: ImageCacheServiceProtocol = MockImageCacheService(),
        locationService: LocationServiceProtocol = MockLocationService()
    ) -> DependencyContainer {
        DependencyContainer(
            weatherService: weatherService,
            geocodingService: geocodingService ?? MockGeocodingService(),
            searchHistoryStorage: searchHistoryStorage,
            imageCacheService: imageCacheService,
            locationService: locationService
        )
    }
}
