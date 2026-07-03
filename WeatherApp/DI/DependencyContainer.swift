import Foundation

/// Central dependency container for constructor injection across coordinators and view models.
struct DependencyContainer {
    let weatherService: WeatherServiceProtocol
    let geocodingService: GeocodingServiceProtocol
    let searchHistoryStorage: SearchHistoryStorageProtocol
    let imageCacheService: ImageCacheServiceProtocol
    let locationService: LocationServiceProtocol

    static func live() -> DependencyContainer {
        let service = OpenWeatherService(session: OpenWeatherConfiguration.makeURLSession())
        return DependencyContainer(
            weatherService: service,
            geocodingService: service,
            searchHistoryStorage: SearchHistoryStorage(),
            imageCacheService: ImageCacheService(),
            locationService: LocationService()
        )
    }
}
