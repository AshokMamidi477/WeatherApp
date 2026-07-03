import Foundation

struct GeocodingResult: Decodable, Equatable, Sendable {
    let name: String
    let state: String?
    let country: String
    let lat: Double
    let lon: Double

    var displayName: String {
        if let state, !state.isEmpty {
            return "\(name), \(state)"
        }
        return name
    }
}

struct WeatherResponse: Decodable, Equatable, Sendable {
    struct Main: Decodable, Equatable, Sendable {
        let temp: Double
        let feelsLike: Double
        let humidity: Int
        let tempMin: Double
        let tempMax: Double

        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case humidity
            case tempMin = "temp_min"
            case tempMax = "temp_max"
        }
    }

    struct Weather: Decodable, Equatable, Sendable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }

    struct Wind: Decodable, Equatable, Sendable {
        let speed: Double
    }

    struct Sys: Decodable, Equatable, Sendable {
        let country: String?
    }

    let name: String
    let main: Main
    let weather: [Weather]
    let wind: Wind
    let sys: Sys?
}

struct WeatherDisplayModel: Equatable, Sendable {
    let cityName: String
    let countryCode: String
    let temperatureFahrenheit: Int
    let feelsLikeFahrenheit: Int
    let highFahrenheit: Int
    let lowFahrenheit: Int
    let humidityPercent: Int
    let windSpeedMPH: Int
    let conditionTitle: String
    let conditionDescription: String
    let iconCode: String

    init(response: WeatherResponse) {
        cityName = response.name
        countryCode = response.sys?.country ?? "US"
        temperatureFahrenheit = Int(response.main.temp.rounded())
        feelsLikeFahrenheit = Int(response.main.feelsLike.rounded())
        highFahrenheit = Int(response.main.tempMax.rounded())
        lowFahrenheit = Int(response.main.tempMin.rounded())
        humidityPercent = response.main.humidity
        windSpeedMPH = Int(response.wind.speed.rounded())

        let primary = response.weather.first
        conditionTitle = primary?.main ?? String(localized: "Unknown")
        conditionDescription = primary?.description.capitalized ?? String(localized: "No description")
        iconCode = primary?.icon ?? "01d"
    }

    var locationTitle: String {
        "\(cityName), \(countryCode)"
    }

    var iconURL: URL? {
        URL(string: "https://openweathermap.org/img/wn/\(iconCode)@2x.png")
    }
}
