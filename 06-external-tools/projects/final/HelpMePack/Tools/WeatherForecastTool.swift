/// Copyright (c) 2026 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import FoundationModels

@Generable(description: "Weather Information for a location.")
struct WeatherInformation {
  let locationName: String
  let forecasts: [WeatherForecast]
}

@Generable(description: "Weather Forecast for a period.")
struct WeatherForecast {
  let name: String
  let startTime: String
  let endTime: String
  let temperature: Int
  let temperatureUnit: String
  let shortForecast: String
  let detailedForecast: String
  let windSpeed: String
  
  init(fromPeriod: WeatherPeriod) {
    self.name = fromPeriod.name
    self.startTime = fromPeriod.startTime.formatted(date: .numeric, time: .shortened)
    self.endTime = fromPeriod.endTime.formatted(date: .numeric, time: .shortened)
    self.temperature = fromPeriod.temperature
    self.temperatureUnit = fromPeriod.temperatureUnit
    self.shortForecast = fromPeriod.shortForecast
    self.detailedForecast = fromPeriod.detailedForecast
    self.windSpeed = fromPeriod.windSpeed
  }
}

struct WeatherForecastTool: Tool {
  let name: String = "WeatherForecastTool"
  let description = "This service returns the weather forecast for the next seven days for a given latitude and longitude."
  
  @Generable
  struct Arguments {
    var latitude: Double
    var longitude: Double
  }

  func call(arguments: Arguments) async throws -> WeatherInformation {
    // 1
    let service = NWSWeatherService()
    do {
      // 2
      let forecast = try await service.forecast(latitude: arguments.latitude, longitude: arguments.longitude)
      // 3
      let convertedForecast = WeatherInformation(
        locationName: forecast.locationName,
        forecasts: forecast.periods.map { WeatherForecast(fromPeriod: $0) }
      )
      return convertedForecast
    }
  }
}
