import Foundation
import Observation

@MainActor
@Observable
final class WeatherSearchViewModel {
    var cityQuery = ""
    var weather: WeatherDisplayModel?
    var isLoading = false
    var errorMessage: String?
    var iconImageData: Data?
    var onStateChange: (() -> Void)?

    private let weatherService: WeatherServiceProtocol
    private let geocodingService: GeocodingServiceProtocol
    private let searchHistoryStorage: SearchHistoryStorageProtocol
    private let imageCacheService: ImageCacheServiceProtocol
    private let locationService: LocationServiceProtocol

    init(dependencies: DependencyContainer) {
        self.weatherService = dependencies.weatherService
        self.geocodingService = dependencies.geocodingService
        self.searchHistoryStorage = dependencies.searchHistoryStorage
        self.imageCacheService = dependencies.imageCacheService
        self.locationService = dependencies.locationService

        if let locationService = dependencies.locationService as? LocationService {
            locationService.onAuthorizationChange = { [weak self] status in
                Task { @MainActor in
                    await self?.handleAuthorizationChange(status)
                }
            }
        }
    }

    func onAppear() {
        locationService.requestAuthorization()
        Task { await bootstrapWeather() }
    }

    func searchTapped() {
        Task { await searchByCity(cityQuery) }
    }

    func bootstrapWeather() async {
        switch locationService.authorizationStatus {
        case .authorized:
            await loadWeatherForCurrentLocation()
        case .notDetermined, .denied, .restricted:
            await loadLastSearchedCityIfAvailable()
        }
    }

    func loadWeatherForCurrentLocation() async {
        await setLoading(true)
        defer {
            isLoading = false
            notifyStateChange()
        }

        do {
            let coordinates = try await locationService.requestCurrentLocation()
            let response = try await weatherService.fetchWeather(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            await applyWeatherResponse(response, persistCity: response.name)
        } catch let error as WeatherError {
            errorMessage = error.errorDescription
            await loadLastSearchedCityIfAvailable(showLocationFallbackMessage: false)
        } catch {
            errorMessage = WeatherError.locationUnavailable.errorDescription
        }
    }

    private func handleAuthorizationChange(_ status: LocationAuthorizationStatus) async {
        guard status == .authorized, weather == nil, !isLoading else { return }
        await loadWeatherForCurrentLocation()
    }

    private func loadLastSearchedCityIfAvailable(showLocationFallbackMessage: Bool = true) async {
        guard let lastCity = searchHistoryStorage.lastSearchedCity() else {
            if showLocationFallbackMessage, errorMessage == nil {
                errorMessage = nil
            }
            return
        }

        cityQuery = lastCity
        await searchByCity(lastCity, persistQuery: false)
    }

    private func searchByCity(_ city: String, persistQuery: Bool = true) async {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = WeatherError.emptySearchQuery.errorDescription
            notifyStateChange()
            return
        }

        await setLoading(true)
        defer {
            isLoading = false
            notifyStateChange()
        }

        do {
            let response = try await weatherService.fetchWeather(city: trimmed, state: nil, country: "US")
            await applyWeatherResponse(response, persistCity: trimmed)
            if persistQuery {
                searchHistoryStorage.saveLastSearchedCity(trimmed)
            }
        } catch let error as WeatherError {
            weather = nil
            iconImageData = nil
            errorMessage = error.errorDescription
        } catch {
            weather = nil
            iconImageData = nil
            errorMessage = WeatherError.invalidResponse.errorDescription
        }
    }

    private func applyWeatherResponse(_ response: WeatherResponse, persistCity: String) async {
        let model = WeatherDisplayModel(response: response)
        weather = model
        errorMessage = nil
        cityQuery = persistCity
        notifyStateChange()

        guard let iconURL = model.iconURL else {
            iconImageData = nil
            return
        }

        // Icons load in the background so weather text appears even if the image request is slow.
        Task {
            iconImageData = try? await imageCacheService.image(for: iconURL)
            notifyStateChange()
        }
    }

    private func setLoading(_ loading: Bool) async {
        isLoading = loading
        if loading {
            errorMessage = nil
            weather = nil
            iconImageData = nil
        }
        notifyStateChange()
    }

    private func notifyStateChange() {
        onStateChange?()
    }
}
