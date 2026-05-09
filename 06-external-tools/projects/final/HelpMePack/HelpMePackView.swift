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
        // Add Button Action
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
}

#Preview {
  HelpMePackView()
}
