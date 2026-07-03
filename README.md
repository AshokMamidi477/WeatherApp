# WeatherApp

A native iOS weather application built using **Swift**, **UIKit**, and **SwiftUI** that allows users to search for weather by city or retrieve weather for their current location using the OpenWeather API.

## Features

* Search weather by US city
* Retrieve weather using the device's current location
* Display temperature, weather conditions, and weather icon
* Cache downloaded weather icons
* Persist the last searched city and automatically restore it on launch
* User-friendly error handling
* Unit tests for ViewModel and networking layers
* No third-party libraries

## Architecture

The project follows the **MVVM-C (Model-View-ViewModel-Coordinator)** architecture with clear separation of concerns.

### Technologies

* Swift
* UIKit + SwiftUI
* MVVM-C
* Dependency Injection
* Async/Await
* URLSession
* Core Location
* NSCache
* Swift Testing
* URLProtocol-based network mocking

## Requirements

* Xcode 16 or later
* iOS 17 or later

## Setup

1. Create a free API key at OpenWeather.
2. Copy the sample configuration file:

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

3. Open `Config/Secrets.xcconfig` and replace:

```
YOUR_API_KEY_HERE
```

with your OpenWeather API key.

4. Open `WeatherApp.xcodeproj` in Xcode.

5. Select an iPhone simulator or physical device.

6. Build and run the application.

## Running Tests

Run all unit tests using:

* **Product → Test**
* or **⌘ + U**

## Security

The real API key is **not committed** to the repository.

`Config/Secrets.xcconfig` is ignored by Git, while `Config/Secrets.xcconfig.example` provides the required template.

For CI environments, the `OPENWEATHER_API_KEY` environment variable can be injected securely or a temporary `Secrets.xcconfig` file can be generated during the build.

## Project Highlights

* Native iOS implementation using UIKit and SwiftUI
* Coordinator-based navigation
* Protocol-oriented dependency injection
* Modern Swift concurrency (async/await)
* Testable networking layer using URLProtocol mocking
* Image caching with NSCache
* Clean, maintainable, and modular architecture
