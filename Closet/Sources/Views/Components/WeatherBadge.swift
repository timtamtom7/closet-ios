import SwiftUI

struct WeatherBadge: View {
    let weather: WeatherService.WeatherInfo?

    var body: some View {
        HStack(spacing: 6) {
            if let weather = weather {
                Image(systemName: weather.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#B8A898"))

                Text(weather.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "#6E6E73"))
            } else {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Loading weather...")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#6E6E73"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: "#FAFAF8"))
        .clipShape(Capsule())
        .overlay {
            Capsule().stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
        }
    }
}
