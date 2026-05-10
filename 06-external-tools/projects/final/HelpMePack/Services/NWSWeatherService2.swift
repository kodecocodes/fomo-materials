import Foundation

enum WeatherServiceError2: Error {
  case invalidCoordinates(latitude: Double, longitude: Double)
  case invalidURL(String)
  case invalidHTTPResponse
  case serverError(statusCode: Int, message: String?)
  case decodingFailed(Error)
  case requestFailed(Error)

  var errorDescription: String? {
    switch self {
    case let .invalidCoordinates(latitude, longitude):
      return "Invalid coordinates: latitude \(latitude), longitude \(longitude)."

    case let .invalidURL(urlString):
      return "Could not create a valid URL from: \(urlString)"

    case .invalidHTTPResponse:
      return "The weather service returned an invalid response."

    case let .serverError(statusCode, message):
      if let message, !message.isEmpty {
        return "The weather service returned status code \(statusCode): \(message)"
      } else {
        return "The weather service returned status code \(statusCode)."
      }

    case let .decodingFailed(error):
      return "Could not read the weather service response: \(error.localizedDescription)"

    case let .requestFailed(error):
      return "Could not contact the weather service: \(error.localizedDescription)"
    }
  }
}

struct NWSWeatherService2 {
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
    guard (-90...90).contains(latitude),
          (-180...180).contains(longitude) else {
      throw WeatherServiceError2.invalidCoordinates(
        latitude: latitude,
        longitude: longitude
      )
    }

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
      throw WeatherServiceError2.invalidURL(urlString)
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

    let data: Data
    let response: URLResponse

    do {
      (data, response) = try await session.data(for: request)
    } catch {
      throw WeatherServiceError2.requestFailed(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw WeatherServiceError2.invalidHTTPResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let message = String(data: data, encoding: .utf8)
      throw WeatherServiceError2.serverError(
        statusCode: httpResponse.statusCode,
        message: message
      )
    }

    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      throw WeatherServiceError2.decodingFailed(error)
    }
  }
}
