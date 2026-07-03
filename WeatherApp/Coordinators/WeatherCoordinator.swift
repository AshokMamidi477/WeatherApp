import UIKit

protocol WeatherCoordinatorDelegate: AnyObject {
    func weatherCoordinatorDidFinish(_ coordinator: WeatherCoordinator)
}

/// Handles navigation for the weather search flow.
final class WeatherCoordinator {
    private let navigationController: UINavigationController
    private let dependencies: DependencyContainer
    weak var delegate: WeatherCoordinatorDelegate?

    init(navigationController: UINavigationController, dependencies: DependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let viewModel = WeatherSearchViewModel(dependencies: dependencies)
        let searchViewController = WeatherSearchViewController(viewModel: viewModel)
        navigationController.setViewControllers([searchViewController], animated: false)
    }
}
