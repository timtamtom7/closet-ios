import Foundation
import WeatherKit
import CoreLocation

/// Weather service using WeatherKit (Apple's native weather API).
/// No API key required — available on iOS 16+ with an Apple ID signed into the device.
@MainActor
class WeatherService: NSObject, ObservableObject {
    static let shared = WeatherService()

    @Published var currentWeather: WeatherInfo?
    @Published var forecasts: [DayForecast] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let weatherService = WeatherKit.WeatherService()
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Request location permission and fetch weather.
    func fetchWeather() async {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isLoading = true
            error = nil
            locationManager.requestLocation()
        case .denied, .restricted:
            error = WeatherError.locationDenied
            isLoading = false
        @unknown default:
            break
        }
    }

    /// Fetch weather for a specific location (used for calendar events in other cities).
    func fetchWeather(latitude: Double, longitude: Double) async {
        isLoading = true
        error = nil

        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let weather = try await weatherService.weather(for: location)
            currentWeather = mapCurrentWeather(weather)
            forecasts = weather.dailyForecast.forecast.prefix(7).map { day in
                DayForecast(
                    date: day.date,
                    high: Int(day.highTemperature.converted(to: .fahrenheit).value),
                    low: Int(day.lowTemperature.converted(to: .fahrenheit).value),
                    condition: mapCondition(day.condition),
                    icon: mapSystemName(day.condition)
                )
            }
        } catch {
            self.error = error
            print("Weather fetch failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Fetch weather for current user location.
    private func fetchWeatherForCurrentLocation() async {
        guard let location = currentLocation else {
            // Use default location if no location available
            await fetchWeather(latitude: 37.7749, longitude: -122.4194)
            return
        }

        await fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    // MARK: - Weather Mapping

    private func mapCurrentWeather(_ weather: Weather) -> WeatherInfo {
        let current = weather.currentWeather

        return WeatherInfo(
            condition: mapCondition(current.condition),
            temperature: Int(current.temperature.converted(to: .fahrenheit).value),
            icon: mapSystemName(current.condition),
            humidity: Int(current.humidity * 100),
            windSpeed: Int(current.wind.speed.converted(to: .milesPerHour).value),
            uvIndex: currentUVIndex
        )
    }

    private var currentUVIndex: Int {
        // WeatherKit doesn't expose UV in CurrentWeather directly in older APIs
        // Fallback: fetch today's forecast for UV
        return 0
    }

    private func mapCondition(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "Clear"
        case .cloudy: return "Cloudy"
        case .mostlyClear: return "Mostly Clear"
        case .mostlyCloudy: return "Mostly Cloudy"
        case .partlyCloudy: return "Partly Cloudy"
        case .rain: return "Rain"
        case .drizzle: return "Drizzle"
        case .heavyRain: return "Heavy Rain"
        case .thunderstorms: return "Thunderstorms"
        case .snow: return "Snow"
        case .flurries: return "Flurries"
        case .sleet: return "Sleet"
        case .freezingRain: return "Freezing Rain"
        case .windy: return "Windy"
        case .foggy: return "Foggy"
        case .haze: return "Haze"
        case .smoky: return "Smoky"
        case .breezy: return "Breezy"
        case .hot: return "Hot"
        case .blowingDust: return "Blowing Dust"
        case .tropicalStorm: return "Tropical Storm"
        case .hurricane: return "Hurricane"
        case .sunShowers: return "Sun Showers"
        case .blowingSnow: return "Blowing Snow"
        case .freezingDrizzle: return "Freezing Drizzle"
        default: return condition.description
        }
    }

    private func mapSystemName(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear, .hot: return "sun.max.fill"
        case .cloudy, .mostlyCloudy, .partlyCloudy: return "cloud.fill"
        case .rain, .drizzle, .heavyRain, .sunShowers: return "cloud.rain.fill"
        case .thunderstorms: return "cloud.bolt.rain.fill"
        case .snow, .flurries, .blowingSnow: return "cloud.snow.fill"
        case .sleet, .freezingRain, .freezingDrizzle: return "cloud.sleet.fill"
        case .windy, .breezy: return "wind"
        case .foggy, .haze, .smoky: return "cloud.fog.fill"
        case .hot: return "thermometer.sun.fill"
        case .hurricane, .tropicalStorm: return "tornado"
        default: return "cloud.fill"
        }
    }

    // MARK: - Mock Data (for development without location)

    func loadMockData() {
        currentWeather = WeatherInfo(
            condition: "Partly Cloudy",
            temperature: 72,
            icon: "cloud.sun.fill",
            humidity: 65,
            windSpeed: 8,
            uvIndex: 5
        )
        forecasts = [
            DayForecast(date: Date(), high: 75, low: 58, condition: "Sunny", icon: "sun.max.fill"),
            DayForecast(date: Date().addingTimeInterval(86400), high: 70, low: 55, condition: "Cloudy", icon: "cloud.fill"),
            DayForecast(date: Date().addingTimeInterval(86400 * 2), high: 65, low: 52, condition: "Rain", icon: "cloud.rain.fill"),
        ]
    }

    /// Lightweight weather info for UI display
    struct WeatherInfo {
        let condition: String
        let temperature: Int
        let icon: String
        var humidity: Int = 0
        var windSpeed: Int = 0
        var uvIndex: Int = 0

        /// Human-readable description of weather
        var description: String {
            "\(temperature)° \(condition)"
        }
    }

    /// Daily forecast for travel packing
    struct DayForecast: Identifiable {
        let id = UUID()
        let date: Date
        let high: Int
        let low: Int
        let condition: String
        let icon: String

        /// Average temperature for the day
        var avgTemp: Int {
            (high + low) / 2
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            await self.fetchWeatherForCurrentLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")

        Task { @MainActor in
            // Fall back to mock data on location error
            self.loadMockData()
            self.isLoading = false
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Task { @MainActor [weak self] in
                self?.locationManager.requestLocation()
            }
        case .denied, .restricted:
            Task { @MainActor [weak self] in
                self?.error = WeatherError.locationDenied
                self?.loadMockData()
                self?.isLoading = false
            }
        default:
            break
        }
    }
}

// MARK: - Errors

enum WeatherError: LocalizedError {
    case locationDenied
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .locationDenied:
            return "Location access denied. Enable in Settings."
        case .networkError:
            return "Unable to fetch weather. Check your connection."
        case .unknown:
            return "Weather unavailable."
        }
    }
}
