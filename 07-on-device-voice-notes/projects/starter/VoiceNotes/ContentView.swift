/// Copyright (c) 2023 Kodeco Inc.
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

struct ContentView: View {
  @EnvironmentObject private var store: VoiceNoteStore

  var body: some View {
    NavigationStack {
      List {
        Section {
          RecorderPanel()
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }

        Section("Notes") {
          if store.hasNotes {
            ForEach(store.notes) { note in
              VoiceNoteRow(note: note)
            }
          } else {
            ContentUnavailableView(
              "No Voice Notes",
              systemImage: "waveform",
              description: Text("Record your first note when you are ready.")
            )
            .listRowBackground(Color.clear)
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Voice Notes")
      #if DEBUG
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Reset Sample Notes", systemImage: "arrow.clockwise.circle") {
            store.resetSampleNotesForTesting()
          }
        }
      }
      #endif
      .alert(
        "Voice Notes",
        isPresented: Binding(
          get: { store.permissionMessage != nil },
          set: { if !$0 { store.permissionMessage = nil } }
        )
      ) {
        Button("OK", role: .cancel) {
          store.permissionMessage = nil
        }
      } message: {
        Text(store.permissionMessage ?? "")
      }
      .navigationDestination(for: VoiceNote.ID.self) { noteID in
        VoiceNoteDetailView(noteID: noteID)
      }
    }
  }
}

func formattedTime(_ time: TimeInterval) -> String {
  let totalSeconds = max(0, Int(time.rounded()))
  let minutes = totalSeconds / 60
  let seconds = totalSeconds % 60
  return "\(minutes):\(String(format: "%02d", seconds))"
}

#Preview {
  ContentView()
    .environmentObject(VoiceNoteStore.mock)
}
