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

struct CompactionIndicatorView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    HStack {
      ZStack {
        Circle()
          .stroke(Color.secondary.opacity(0.25), lineWidth: 2)
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { context in
          let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.0)
          Circle()
            .trim(from: 0.12, to: 0.62)
            .stroke(
              Color.blue,
              style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: 22, height: 22)
            .rotationEffect(.degrees(phase * 360.0))
        }
      }
      .frame(width: 22, height: 22)

      VStack(alignment: .leading, spacing: 2) {
        Text("Compacting context…")
          .font(.subheadline.weight(.semibold))

        Text("Summarizing older messages")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color(.systemGray6))
    )
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Compacting conversation context")
    .accessibilityHint("The app is summarizing earlier messages to fit the context window")
    .transition(.opacity)
  }
}

#Preview {
  CompactionIndicatorView()
    .padding()
}

