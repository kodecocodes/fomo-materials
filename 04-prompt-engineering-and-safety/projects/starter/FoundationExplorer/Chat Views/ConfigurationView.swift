/// Copyright (c) 2025 Kodeco Inc.
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

struct ConfigurationView: View {
  @Environment(\.dismiss)
    var dismiss
  @Binding var settings: PromptSettings

  @State private var thresholdError: String?
  @State private var topError: String?

  // Derived bindings to bridge optionals / numbers to text controls
  private var instructionText: Binding<String> {
    Binding(
      get: { settings.instructions ?? "" },
      set: { settings.instructions = $0.isEmpty ? nil : $0 }
    )
  }

  private var temperatureValue: Binding<Double> {
    Binding(
      get: { settings.temperature ?? 0.2 },
      set: { settings.temperature = $0 }
    )
  }

  private var thresholdText: Binding<String> {
    Binding(
      get: { String(format: "%.3f", settings.sampling.threshold) },
      set: { newText in
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let val = Double(trimmed), (0.0...1.0).contains(val) {
          settings.sampling.threshold = val
          thresholdError = nil
        } else {
          thresholdError = "Enter a number between 0.0 and 1.0"
        }
      }
    )
  }

  private var topText: Binding<String> {
    Binding(
      get: { String(settings.sampling.top) },
      set: { newText in
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let val = Int(trimmed) {
          settings.sampling.top = val
          topError = nil
        } else {
          topError = "Please enter a valid integer"
        }
      }
    )
  }

  var body: some View {
    NavigationStack {
      Text("Settings")
        .font(.title)
      Form {
        Section("Instructions") {
          TextEditor(text: instructionText)
          Text("Changing the instructions will clear the current session.")
            .font(.caption.bold())
        }
        Section("Temperature") {
          Toggle(isOn: Binding(
            get: { settings.temperature != nil },
            set: { useCustom in
              if useCustom {
                if settings.temperature == nil { settings.temperature = 0.2 }
              } else {
                settings.temperature = nil
              }
            }
          )) {
            HStack {
              Text("Custom Temperature")
              if settings.temperature != nil {
                Spacer()
                Text(temperatureValue.wrappedValue, format: .number)
              } else {
                Spacer()
              }
            }
          }
          HStack {
            Slider(value: temperatureValue, in: 0...1, step: 0.1)
          }
          .opacity(settings.temperature != nil ? 1.0 : 0.0)
        }
        Section("Sampling") {
          Picker("Sampling Method", selection: $settings.sampling.type) {
            ForEach(SampleType.allCases) { sample in
              Text(sample.title).tag(sample)
            }
          }
          .pickerStyle(.segmented)

          VStack {
            if settings.sampling.type == .threshold {
              HStack {
                Text("Probability Threshold:")
                TextField("Enter a value 0.0 – 1.0", text: thresholdText)
                  .keyboardType(.decimalPad)
                  .textFieldStyle(.roundedBorder)
                if let thresholdError {
                  Text(thresholdError)
                    .font(.caption)
                    .foregroundStyle(.red)
                }
              }
              .transition(.opacity)
            }
            if settings.sampling.type == .top {
              HStack {
                Text("Top:")
                TextField("Enter a value:", text: topText)
                  .keyboardType(.numberPad)
                  .textFieldStyle(.roundedBorder)
                if let topError {
                  Text(topError)
                    .font(.caption)
                    .foregroundStyle(.red)
                }
              }
              .transition(.opacity)
            }
            if settings.sampling.type == .threshold || settings.sampling.type == .top {
              SeedEditorView(seed: $settings.sampling.seed)
                .transition(.opacity)
            }
          }
          .animation(.default, value: settings.sampling.type)
        }
      }
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", systemImage: "checkmark") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var settings = PromptSettings(
    instructions: nil,
    temperature: 0.2,
    sampling: SamplingOptions(type: .system, threshold: 0.333, top: 10, seed: nil)
  )
  ConfigurationView(settings: $settings)
}
