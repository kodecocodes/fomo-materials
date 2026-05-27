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

struct RecorderPanel: View {
  @EnvironmentObject private var store: VoiceNoteStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  
  var body: some View {
    VStack(spacing: 20) {
      VStack(spacing: 8) {
        ZStack {
          Image(systemName: "mic.circle.fill")
            .foregroundStyle(.tint)
            .opacity(store.isRecording ? 0 : 1)
          
          Image(systemName: "waveform")
            .symbolEffect(
              .variableColor.iterative.dimInactiveLayers.nonReversing,
              options: reduceMotion ? .default : .repeat(.continuous)
            )
            .foregroundStyle(.red)
            .opacity(store.isRecording ? 1 : 0)
        }
        .font(.system(size: 56, weight: .regular))
        .frame(width: 72, height: 64)
        
        Text(store.isRecording ? formattedTime(store.elapsedTime) : "Ready to Record")
          .contentTransition(.numericText())
          .font(.system(.title2, design: .rounded, weight: .semibold))
          .monospacedDigit()
      }
      .frame(maxWidth: .infinity)
      .animation(.snappy, value: store.isRecording)
      
      Button {
        if store.isRecording {
          store.stopRecording()
        } else {
          Task {
            await store.startRecording()
          }
        }
      } label: {
        Label(
          store.isRecording ? "Stop Recording" : "Record Note",
          systemImage: store.isRecording ? "stop.fill" : "record.circle"
        )
        .foregroundStyle(.white)
        .contentTransition(.symbolEffect(.replace))
        .font(.title3)
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .tint(store.isRecording ? .red : .accentColor)
      .animation(.snappy, value: store.isRecording)
    }
    .padding(20)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
  }
}

#Preview {
  RecorderPanel()
    .environmentObject(VoiceNoteStore.mock)
}
