import SwiftUI
import UIKit

/// UIKit search screen hosting the SwiftUI weather detail panel below the search controls.
final class WeatherSearchViewController: UIViewController {
    private let viewModel: WeatherSearchViewModel

    private let cityTextField: UITextField = {
        let field = UITextField()
        field.placeholder = String(localized: "Enter US city")
        field.borderStyle = .roundedRect
        field.autocorrectionType = .no
        field.returnKeyType = .search
        field.accessibilityLabel = String(localized: "City search field")
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let searchButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "Search")
        let button = UIButton(configuration: config)
        button.accessibilityLabel = String(localized: "Search weather")
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let hostingController: UIHostingController<WeatherDetailContainerView>

    init(viewModel: WeatherSearchViewModel) {
        self.viewModel = viewModel
        self.hostingController = UIHostingController(
            rootView: WeatherDetailContainerView(viewModel: viewModel)
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Storyboards are intentionally unsupported.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Weather")
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        configureLayout()
        configureActions()
        viewModel.onStateChange = { [weak self] in
            guard let self else { return }
            self.render(viewModel: self.viewModel)
        }
        render(viewModel: viewModel)
        viewModel.onAppear()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.view.setNeedsLayout()
        }
    }

    private func configureLayout() {
        let searchStack = UIStackView(arrangedSubviews: [cityTextField, searchButton, activityIndicator])
        searchStack.axis = .horizontal
        searchStack.spacing = 8
        searchStack.alignment = .center
        searchStack.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        if #available(iOS 16.4, *) {
            hostingController.safeAreaRegions = []
        }

        view.addSubview(searchStack)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            searchStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            searchStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            searchStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),

            cityTextField.heightAnchor.constraint(equalToConstant: 40),
            searchButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 72),

            hostingController.view.topAnchor.constraint(equalTo: searchStack.bottomAnchor, constant: 4),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureActions() {
        cityTextField.delegate = self
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
    }

    private func render(viewModel: WeatherSearchViewModel) {
        if cityTextField.text != viewModel.cityQuery {
            cityTextField.text = viewModel.cityQuery
        }

        if viewModel.isLoading {
            activityIndicator.startAnimating()
            searchButton.isEnabled = false
        } else {
            activityIndicator.stopAnimating()
            searchButton.isEnabled = true
        }

        hostingController.rootView = WeatherDetailContainerView(viewModel: viewModel)
    }

    @objc private func searchTapped() {
        view.endEditing(true)
        viewModel.cityQuery = cityTextField.text ?? ""
        viewModel.searchTapped()
    }
}

extension WeatherSearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTapped()
        return true
    }
}

private struct WeatherDetailContainerView: View {
    @Bindable var viewModel: WeatherSearchViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView(String(localized: "Loading weather…"))
            } else if let weather = viewModel.weather {
                WeatherDetailView(weather: weather, iconImageData: viewModel.iconImageData)
            } else if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                ContentUnavailableView(
                    String(localized: "Search failed"),
                    systemImage: "exclamationmark.cloud",
                    description: Text(errorMessage)
                )
            } else {
                ContentUnavailableView(
                    String(localized: "Search for a city"),
                    systemImage: "cloud.sun",
                    description: Text(String(localized: "Enter a US city or allow location access to see current conditions."))
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
