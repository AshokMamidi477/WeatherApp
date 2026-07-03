import CoreLocation
import Foundation

/// Wraps CLLocationManager so view models stay testable without Core Location.
final class LocationService: NSObject, LocationServiceProtocol, @unchecked Sendable {
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<(latitude: Double, longitude: Double), Error>?
    private let locationTimeout: Duration

    var onAuthorizationChange: (@Sendable (LocationAuthorizationStatus) -> Void)?

    var authorizationStatus: LocationAuthorizationStatus {
        mapAuthorization(manager.authorizationStatus)
    }

    override init() {
        manager = CLLocationManager()
        locationTimeout = .seconds(10)
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    init(manager: CLLocationManager, locationTimeout: Duration = .seconds(10)) {
        self.manager = manager
        self.locationTimeout = locationTimeout
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() async throws -> (latitude: Double, longitude: Double) {
        switch authorizationStatus {
        case .denied, .restricted:
            throw WeatherError.locationDenied
        case .notDetermined:
            throw WeatherError.locationUnavailable
        case .authorized:
            break
        }

        return try await withThrowingTaskGroup(of: (latitude: Double, longitude: Double).self) { group in
            group.addTask { try await self.requestLocationUpdate() }

            group.addTask {
                try await Task.sleep(for: self.locationTimeout)
                throw WeatherError.locationUnavailable
            }

            guard let location = try await group.next() else {
                throw WeatherError.locationUnavailable
            }

            group.cancelAll()
            return location
        }
    }

    private func requestLocationUpdate() async throws -> (latitude: Double, longitude: Double) {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    private func mapAuthorization(_ status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .restricted
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChange?(authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            continuation?.resume(throwing: WeatherError.locationUnavailable)
            continuation = nil
            return
        }

        continuation?.resume(returning: (location.coordinate.latitude, location.coordinate.longitude))
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: WeatherError.locationUnavailable)
        continuation = nil
    }
}
