import Foundation

actor WeatherService {
    static let shared = WeatherService()

    private init() {}

    struct WeatherInfo {
        let condition: String
        let temperature: Double
        let icon: String

        var description: String {
            "\(Int(temperature))° \(condition)"
        }

        var isRainy: Bool {
            condition == "Rainy" || condition == "Stormy"
        }

        var isCold: Bool {
            temperature < 15
        }

        var isHot: Bool {
            temperature > 25
        }
    }

    struct DayForecast: Identifiable {
        let id = UUID()
        let date: Date
        let avgTemp: Double
        let maxTemp: Double
        let minTemp: Double
        let condition: String
        let icon: String
    }

    func fetchWeather(latitude: Double = 37.7749, longitude: Double = -122.4194) async throws -> WeatherInfo {
        let urlString = "https://wttr.in/?format=j1"
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let currentCondition = (json["current_condition"] as? [[String: Any]])?.first else {
            throw WeatherError.parseError
        }

        let tempC = Double(currentCondition["temp_C"] as? String ?? "20") ?? 20
        let weatherCode = Int(currentCondition["weatherCode"] as? String ?? "0") ?? 0
        let condition = weatherCondition(from: weatherCode)
        let icon = weatherIcon(from: condition)

        return WeatherInfo(condition: condition, temperature: tempC, icon: icon)
    }

    func fetchForecast(days: Int = 5) async throws -> [DayForecast] {
        let urlString = "https://wttr.in/?format=j1"
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let weather = (json["weather"] as? [[String: Any]]) else {
            throw WeatherError.parseError
        }

        var forecasts: [DayForecast] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for (index, day) in weather.prefix(days).enumerated() {
            let dateString = day["date"] as? String ?? ""
            let date = dateFormatter.date(from: dateString) ?? Date().addingTimeInterval(TimeInterval(index * 86400))

            let avgTempC = Double(day["avgtempC"] as? String ?? "20") ?? 20
            let maxTempC = Double(day["maxtempC"] as? String ?? "25") ?? 25
            let minTempC = Double(day["mintempC"] as? String ?? "15") ?? 15

            let hourlyData = (day["hourly"] as? [[String: Any]]) ?? []
            let weatherCode = Int((hourlyData.first?["weatherCode"] as? String) ?? "0") ?? 0
            let condition = weatherCondition(from: weatherCode)
            let icon = weatherIcon(from: condition)

            forecasts.append(DayForecast(
                date: date,
                avgTemp: avgTempC,
                maxTemp: maxTempC,
                minTemp: minTempC,
                condition: condition,
                icon: icon
            ))
        }

        return forecasts
    }

    private func weatherCondition(from code: Int) -> String {
        switch code {
        case 113: return "Sunny"
        case 116: return "Partly Cloudy"
        case 119, 122: return "Cloudy"
        case 143, 248, 260: return "Foggy"
        case 176, 263, 266, 353, 355, 356, 359, 362, 365, 377, 389, 392: return "Rainy"
        case 179, 362, 368, 371, 373, 374, 377, 386, 395: return "Snowy"
        case 200, 386, 389, 392: return "Stormy"
        default: return "Clear"
        }
    }

    private func weatherIcon(from condition: String) -> String {
        switch condition {
        case "Sunny": return "sun.max.fill"
        case "Partly Cloudy": return "cloud.sun.fill"
        case "Cloudy": return "cloud.fill"
        case "Foggy": return "cloud.fog.fill"
        case "Rainy": return "cloud.rain.fill"
        case "Snowy": return "snow"
        case "Stormy": return "cloud.bolt.rain.fill"
        default: return "sun.max.fill"
        }
    }
}

enum WeatherError: Error {
    case invalidURL
    case parseError
    case networkError
}
