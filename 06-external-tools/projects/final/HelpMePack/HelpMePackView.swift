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

import SwiftUI
import FoundationModels

struct HelpMePackView: View {
  @State var information = PackingInformation()
  @State var showTranscript = false
  @State var isLoading = false
  @State var session = LanguageModelSession()
  @State var startDate = Date.now
  @State var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date.now)!
  private var availableDateRange: ClosedRange<Date> {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: Date())
    let end = calendar.date(byAdding: .day, value: 7, to: start)!
    return start...end
  }
  @State var destinationCoordinates: GeocodedLocation?
  
  var body: some View {
    NavigationStack {
      Form {
        tripSection
        packingSection
      }
      .toolbar {
        appToolbar
      }
      .navigationTitle("Help Me Pack")
      .onChange(of: startDate) {
        endDate = max(min(endDate, availableDateRange.upperBound), startDate)
      }
    }
  }
  
  @ToolbarContentBuilder private var appToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      NavigationLink {
        TranscriptView(session: $session)
      } label: {
        Image(systemName: "text.page")
      }
    }
  }
  
  
  private var tripSection: some View {
    Section("Trip") {
      TextField("Destination City", text: $information.destination)
        .textInputAutocapitalization(.words)
        .task(id: information.destination) {
          do {
            try await Task.sleep(nanoseconds: 500_000_000)
            destinationCoordinates = try await GeocodingService.coordinates(for: information.destination)
          } catch {
            print(error.localizedDescription)
          }
        }
      if let destination = destinationCoordinates {
        Text(
          "Lat: \(destination.latitude.formatted(.number.precision(.fractionLength(2)))) " +
          "Long: \(destination.longitude.formatted(.number.precision(.fractionLength(2))))"
        )
        .font(.caption2)
      }
      DatePicker(
        "Start Date",
        selection: $startDate,
        in: availableDateRange,
        displayedComponents: .date
      )
      DatePicker(
        "End Date",
        selection: $endDate,
        in: availableDateRange,
        displayedComponents: .date
      )
      Button {
        createNewSession()
        generatePackingList()
      } label: {
        generateButtonLabel
          .frame(maxWidth: .infinity, alignment: .center)
      }
      .disabled(
        information.destination.isEmpty ||
        isLoading ||
        session.isResponding
      )
    }
  }
  
  @ViewBuilder
  private var generateButtonLabel: some View {
    if isLoading {
      ProgressView()
    } else if startDate > endDate {
      Text("Error: Start Date Must Be Before End Date")
        .foregroundStyle(.red)
        .bold()
    } else {
      Text("Generate Packing List")
    }
  }
  
  private var packingSection: some View {
    Section("Packing Recommendation") {
      if information.packingRecommendation.isEmpty {
        Text("Your recommendation will appear here.")
          .foregroundStyle(.secondary)
      } else {
        Text(LocalizedStringKey(information.packingRecommendation))
      }
    }
  }
  
  func createNewSession() {
    // 1
    let instructions = """
      You are a packing assistant that creates practical packing lists for travelers.

      Use the available tools whenever current weather information is needed.
      Also use available tools to convert locations and city names into
      latitude and longitude
      Do not guess weather conditions, temperatures, or precipitation.

      When creating a packing list:
      - First determine the trip destination and dates.
      - Use tools to get the forecast for the destination and travel dates.
      - Base weather-related recommendations on tool results.
      - Recommend only items that are useful for the trip conditions.
      - Keep the list concise, realistic, and grouped by category.
      - Explain briefly why weather-specific items are included.
      """
    
    // 2
    session = LanguageModelSession(
      tools: [GeoLookupTool(), WeatherForecastTool()],
      instructions: instructions
    )
  }
  
  func generatePackingList() {
    // 1
    let prompt = """
    Create a weather-aware packing list for this trip.

    Destination: \(information.destination).
    Travel dates: \(startDate.formatted(date: .numeric, time: .omitted)) through \(endDate.formatted(date: .numeric, time: .omitted)).

    1. Retrieve the weather forecast for the travel dates.
    2. Use the forecast to decide what clothing and accessories are needed.

    Do not assume weather conditions from general knowledge.
    """

    // 2
    Task {
      // 3
      isLoading = true
      defer {
        isLoading = false
      }
      // 4
      let stream = session.streamResponse(to: prompt)
      // 5
      do {
        for try await partialResponse in stream {
          information.packingRecommendation = partialResponse.content
        }
        // 6
        // 1
      } catch let error as LanguageModelSession.ToolCallError {
        var errorString: String
        // 2
        errorString = "Error occurred in \(error.tool.name)\n"
        // 3
        // 1
        if let underlyingError = error.underlyingError as? WeatherServiceError2 {
          // 2
          if case let .serverError(_, message) = underlyingError {
            // 3
            if message?.contains("Data Unavailable For Requested Point") ?? false {
              errorString += """
              The requested location is not covered by the National Weather Service.
              
              Please Check Your Location and Try Again.
              """
            } else {
              errorString += underlyingError.errorDescription ?? error.localizedDescription
            }
          // 4
          } else {
            errorString += underlyingError.errorDescription ?? error.localizedDescription
          }
        }
        // 4
        information.packingRecommendation = errorString
      } catch {
        information.packingRecommendation = "Error: \(error.localizedDescription)"
      }
    }
  }
}

#Preview {
  HelpMePackView()
}
