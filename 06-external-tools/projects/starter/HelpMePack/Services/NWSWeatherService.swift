import Foundation

struct WeatherSummary: Sendable {
  let locationName: String
  let periods: [WeatherPeriod]
}

struct WeatherPeriod: Sendable {
  let name: String
  let startTime: Date
  let endTime: Date
  let temperature: Int
  let temperatureUnit: String
  let shortForecast: String
  let detailedForecast: String
  let windSpeed: String
}

enum WeatherServiceError: Error {
  case invalidURL
  case invalidResponse
}

struct NWSWeatherService {
  private let session: URLSession
  private let decoder: JSONDecoder
  private let userAgent: String

  init(
    session: URLSession = .shared,
    //  Change Below to Your Email
    userAgent: String = "HelpMePack/1.0 email@example.com"
  ) {
    self.session = session
    self.userAgent = userAgent

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    self.decoder = decoder
  }

  func forecast(latitude: Double, longitude: Double) async throws -> WeatherSummary {
    let point = try await fetchPointMetadata(
      latitude: latitude,
      longitude: longitude
    )

    let forecastResponse = try await fetchForecast(
      from: point.properties.forecast
    )

    return WeatherSummary(
      locationName: "\(point.properties.relativeLocation.properties.city), \(point.properties.relativeLocation.properties.state)",
      periods: forecastResponse.properties.periods.map { period in
        WeatherPeriod(
          name: period.name,
          startTime: period.startTime,
          endTime: period.endTime,
          temperature: period.temperature,
          temperatureUnit: period.temperatureUnit,
          shortForecast: period.shortForecast,
          detailedForecast: period.detailedForecast,
          windSpeed: period.windSpeed
        )
      }
    )
  }

  private func fetchPointMetadata(
    latitude: Double,
    longitude: Double
  ) async throws -> NWSPointResponse {
    let urlString = "https://api.weather.gov/points/\(latitude),\(longitude)"

    guard let url = URL(string: urlString) else {
      throw WeatherServiceError.invalidURL
    }

    return try await get(url)
  }

  private func fetchForecast(from url: URL) async throws -> NWSForecastResponse {
    try await get(url)
  }

  private func get<T: Decodable>(_ url: URL) async throws -> T {
    var request = URLRequest(url: url)
    request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue("application/geo+json", forHTTPHeaderField: "Accept")

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200..<300).contains(httpResponse.statusCode) else {
      throw WeatherServiceError.invalidResponse
    }

    return try decoder.decode(T.self, from: data)
  }
}

struct NWSPointResponse: Decodable {
  let properties: Properties

  struct Properties: Decodable {
    let forecast: URL
    let relativeLocation: RelativeLocation
  }

  struct RelativeLocation: Decodable {
    let properties: LocationProperties
  }

  struct LocationProperties: Decodable {
    let city: String
    let state: String
  }
}

struct NWSForecastResponse: Decodable {
  let properties: Properties

  struct Properties: Decodable {
    let periods: [Period]
  }

  struct Period: Decodable {
    let name: String
    let startTime: Date
    let endTime: Date
    let temperature: Int
    let temperatureUnit: String
    let windSpeed: String
    let shortForecast: String
    let detailedForecast: String
  }
}
