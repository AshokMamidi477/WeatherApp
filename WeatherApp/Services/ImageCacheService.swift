import Foundation

/// Simple in-memory + disk cache for weather icon downloads.
final class ImageCacheService: ImageCacheServiceProtocol, @unchecked Sendable {
    private let memoryCache = NSCache<NSURL, NSData>()
    private let fileManager: FileManager
    private let session: URLSession
    private let cacheDirectory: URL

    init(
        session: URLSession = OpenWeatherConfiguration.makeURLSession(),
        fileManager: FileManager = .default
    ) {
        self.session = session
        self.fileManager = fileManager

        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        cacheDirectory = base.appendingPathComponent("WeatherIcons", isDirectory: true)

        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }

        memoryCache.countLimit = 100
    }

    func image(for url: URL) async throws -> Data {
        let key = url as NSURL

        if let cached = memoryCache.object(forKey: key) {
            return cached as Data
        }

        let diskURL = diskURL(for: url)
        if fileManager.fileExists(atPath: diskURL.path),
           let data = try? Data(contentsOf: diskURL) {
            memoryCache.setObject(data as NSData, forKey: key)
            return data
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw WeatherError.invalidResponse
            }

            memoryCache.setObject(data as NSData, forKey: key)
            try? data.write(to: diskURL, options: .atomic)
            return data
        } catch let error as WeatherError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw WeatherError.networkUnavailable
        } catch {
            throw WeatherError.invalidResponse
        }
    }

    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func diskURL(for url: URL) -> URL {
        let fileName = url.lastPathComponent.replacingOccurrences(of: "@", with: "_")
        return cacheDirectory.appendingPathComponent(fileName)
    }
}
