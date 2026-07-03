import Foundation
import Testing
@testable import WeatherApp

@MainActor
struct WeatherSearchViewModelTests {
    @Test
    func searchByCityUpdatesWeatherAndPersistsHistory() async {
        let weatherService = MockWeatherService()
        weatherService.weatherByCityResult = .success(WeatherFixture.austinResponse)

        let history = MockSearchHistoryStorage()
        let dependencies = DependencyContainer.mock(
            weatherService: weatherService,
            searchHistoryStorage: history,
            locationService: MockLocationService()
        )

        let viewModel = WeatherSearchViewModel(dependencies: dependencies)
        viewModel.cityQuery = "Austin"
        viewModel.searchTapped()

        try? await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.weather?.cityName == "Austin")
        #expect(history.savedCities.last == "Austin")
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func emptySearchShowsValidationMessage() async {
        let viewModel = WeatherSearchViewModel(dependencies: .mock(weatherService: MockWeatherService()))
        viewModel.cityQuery = "   "
        viewModel.searchTapped()

        try? await Task.sleep(for: .milliseconds(50))

        #expect(viewModel.errorMessage == WeatherError.emptySearchQuery.errorDescription)
    }

    @Test
    func bootstrapLoadsLastCityWhenLocationUnavailable() async {
        let weatherService = MockWeatherService()
        weatherService.weatherByCityResult = .success(WeatherFixture.austinResponse)

        let history = MockSearchHistoryStorage()
        history.storedCity = "Dallas"

        let location = MockLocationService()
        location.authorizationStatus = .denied

        let viewModel = WeatherSearchViewModel(
            dependencies: .mock(
                weatherService: weatherService,
                searchHistoryStorage: history,
                locationService: location
            )
        )

        await viewModel.bootstrapWeather()

        #expect(viewModel.cityQuery == "Dallas")
        #expect(viewModel.weather?.cityName == "Austin")
    }

    @Test
    func authorizedLocationLoadsCurrentWeather() async {
        let weatherService = MockWeatherService()
        weatherService.weatherByCoordinatesResult = .success(WeatherFixture.austinResponse)

        let location = MockLocationService()
        location.authorizationStatus = .authorized

        let viewModel = WeatherSearchViewModel(
            dependencies: .mock(
                weatherService: weatherService,
                locationService: location
            )
        )

        await viewModel.loadWeatherForCurrentLocation()

        #expect(weatherService.fetchWeatherByCoordinatesCalls.count == 1)
        #expect(viewModel.weather?.cityName == "Austin")
        #expect(viewModel.isLoading == false)
    }

    @Test
    func invalidCitySearchClearsPreviousWeatherAndShowsError() async {
        let weatherService = MockWeatherService()
        weatherService.weatherByCityResult = .success(WeatherFixture.austinResponse)

        let viewModel = WeatherSearchViewModel(
            dependencies: .mock(
                weatherService: weatherService,
                locationService: MockLocationService()
            )
        )

        viewModel.cityQuery = "Austin"
        viewModel.searchTapped()
        try? await Task.sleep(for: .milliseconds(150))
        #expect(viewModel.weather?.cityName == "Austin")

        weatherService.weatherByCityResult = .failure(WeatherError.cityNotFound)
        viewModel.cityQuery = "liii"
        viewModel.searchTapped()
        try? await Task.sleep(for: .milliseconds(150))

        #expect(viewModel.isLoading == false)
        #expect(viewModel.weather == nil)
        #expect(viewModel.errorMessage == WeatherError.cityNotFound.errorDescription)
    }
}
