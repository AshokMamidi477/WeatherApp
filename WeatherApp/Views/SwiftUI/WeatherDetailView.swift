import SwiftUI

struct WeatherDetailView: View {
    let weather: WeatherDisplayModel
    let iconImageData: Data?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            Group {
                if horizontalSizeClass == .regular {
                    regularLayout
                } else {
                    compactLayout
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.visible)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .contain)
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            metricsGrid(columns: 2)
        }
    }

    private var regularLayout: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                header
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            metricsGrid(columns: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(weather.locationTitle)
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            HStack(alignment: .center, spacing: 10) {
                WeatherIconView(imageData: iconImageData, accessibilityLabel: weather.conditionTitle)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(weather.temperatureFahrenheit)°")
                        .font(.system(size: 40, weight: .thin))
                        .accessibilityLabel(String(localized: "Temperature \(weather.temperatureFahrenheit) degrees Fahrenheit"))

                    Text(weather.conditionDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(String(localized: "Feels like \(weather.feelsLikeFahrenheit)°"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func metricsGrid(columns: Int) -> some View {
        let items: [(String, String)] = [
            (String(localized: "High"), "\(weather.highFahrenheit)°"),
            (String(localized: "Low"), "\(weather.lowFahrenheit)°"),
            (String(localized: "Humidity"), "\(weather.humidityPercent)%"),
            (String(localized: "Wind"), "\(weather.windSpeedMPH) mph")
        ]

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
            ForEach(items, id: \.0) { title, value in
                WeatherMetricCard(title: title, value: value)
            }
        }
    }
}

private struct WeatherMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }
}

struct WeatherIconView: View {
    let imageData: Data?
    let accessibilityLabel: String

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "cloud.sun.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    WeatherDetailView(
        weather: WeatherDisplayModel(
            response: WeatherResponse(
                name: "Austin",
                main: .init(temp: 82, feelsLike: 85, humidity: 55, tempMin: 70, tempMax: 90),
                weather: [.init(id: 800, main: "Clear", description: "clear sky", icon: "01d")],
                wind: .init(speed: 8),
                sys: .init(country: "US")
            )
        ),
        iconImageData: nil
    )
}
