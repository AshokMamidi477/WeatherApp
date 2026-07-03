import UIKit

/// Root coordinator that bootstraps the application flow.
final class AppCoordinator {
    private let window: UIWindow
    private let dependencies: DependencyContainer
    private var weatherCoordinator: WeatherCoordinator?

    init(window: UIWindow, dependencies: DependencyContainer = .live()) {
        self.window = window
        self.dependencies = dependencies
    }

    func start() {
        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = false

        let weatherCoordinator = WeatherCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )
        weatherCoordinator.delegate = self
        self.weatherCoordinator = weatherCoordinator
        weatherCoordinator.start()

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

extension AppCoordinator: WeatherCoordinatorDelegate {
    func weatherCoordinatorDidFinish(_ coordinator: WeatherCoordinator) {
        weatherCoordinator = nil
    }
}
