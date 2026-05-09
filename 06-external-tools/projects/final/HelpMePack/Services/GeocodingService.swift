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

import MapKit
import FoundationModels

enum GeocodingError: Error {
  case invalidRequest
  case noMatchingLocation
}

@Generable(description: "Contains a location name and the latitude and longitude for that location.")
struct GeocodedLocation {
  @Guide(description: "Location Name")
  let name: String
  @Guide(description: "Latitude of Location")
  let latitude: Double
  @Guide(description: "Longitude of Location")
  let longitude: Double
}

struct GeocodingService {
  // 1
  static func coordinates(for placeName: String) async throws -> GeocodedLocation {
    // 2
    guard let request = MKGeocodingRequest(addressString: placeName) else {
      throw GeocodingError.invalidRequest
    }

    // 3
    let mapItems = try await request.mapItems
    guard let item = mapItems.first else {
      throw GeocodingError.noMatchingLocation
    }

    // 4
    let coordinate = item.location.coordinate
    let name =
      item.name ??
      item.address?.shortAddress ??
      item.address?.fullAddress ??
      placeName

    // 5
    return GeocodedLocation(
      name: name,
      latitude: coordinate.latitude,
      longitude: coordinate.longitude
    )
  }
}
