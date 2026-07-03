import Foundation

final class SearchHistoryStorage: SearchHistoryStorageProtocol, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "lastSearchedCity"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveLastSearchedCity(_ city: String) {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        defaults.set(trimmed, forKey: key)
    }

    func lastSearchedCity() -> String? {
        defaults.string(forKey: key)
    }
}
