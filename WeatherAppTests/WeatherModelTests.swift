import Foundation
import Testing
@testable import WeatherApp

struct WeatherDisplayModelTests {
    @Test
    func mapsResponseIntoDisplayValues() {
        let model = WeatherDisplayModel(response: WeatherFixture.austinResponse)

        #expect(model.cityName == "Austin")
        #expect(model.countryCode == "US")
        #expect(model.temperatureFahrenheit == 82)
        #expect(model.conditionTitle == "Clear")
        #expect(model.iconURL?.absoluteString.contains("01d@2x.png") == true)
    }
}

@Suite(.serialized)
struct OpenWeatherServiceTests {
    @Test
    func geocodeUsesResolvedAPIKeyFromInitializer() async throws {
        let json = """
        [{"name":"Houston","state":"TX","country":"US","lat":29.76,"lon":-95.36}]
        """.data(using: .utf8)!

        let session = URLSession.mock(data: json, statusCode: 200) { request in
            let query = request.url?.query ?? ""
            #expect(query.contains("appid=test-key"))
        }

        let service = OpenWeatherService(session: session, apiKey: "test-key")
        let result = try await service.geocode(city: "Houston", state: nil, country: "US")
        #expect(result.name == "Houston")
    }

    @Test
    func geocodeThrowsWhenCityMissing() async {
        let session = URLSession.mock(data: Data("[]".utf8), statusCode: 200)
        let service = OpenWeatherService(session: session, apiKey: "test-key")

        await #expect(throws: WeatherError.cityNotFound) {
            _ = try await service.geocode(city: "Nowhere", state: nil, country: "US")
        }
    }

    @Test
    func fetchWeatherThrowsWhenAPIKeyMissing() async {
        let service = OpenWeatherService(session: OpenWeatherConfiguration.makeURLSession(), apiKey: "")

        await #expect(throws: WeatherError.missingAPIKey) {
            _ = try await service.fetchWeather(latitude: 1, longitude: 1)
        }
    }
}

private extension URLSession {
    static func mock(
        data: Data,
        statusCode: Int,
        validateRequest: (@Sendable (URLRequest) -> Void)? = nil
    ) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        MockURLProtocol.requestHandler = { request in
            validateRequest?(request)
            return (
                HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!,
                data
            )
        }
        return URLSession(configuration: config)
    }
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
