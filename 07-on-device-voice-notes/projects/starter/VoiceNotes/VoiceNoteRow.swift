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

struct VoiceNoteRow: View {
  @EnvironmentObject private var store: VoiceNoteStore
  let note: VoiceNote
  
  var body: some View {
    HStack(spacing: 12) {
      Button {
        store.togglePlayback(for: note)
      } label: {
        Image(systemName: store.playingNoteID == note.id ? "pause.fill" : "play.fill")
          .frame(width: 32, height: 32)
          .accessibilityLabel(
            store.playingNoteID == note.id ? "Pause \(note.title)" : "Play \(note.title)"
          )
      }
      .buttonStyle(.bordered)
      .clipShape(Circle())
      
      NavigationLink(value: note.id) {
        VStack(alignment: .leading, spacing: 4) {
          Text(note.title)
            .font(.headline)
            .lineLimit(1)
          
          Text("\(note.createdAt.formatted(date: .abbreviated, time: .shortened)) • \(formattedTime(note.duration))")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          
          TranscriptSummary(note: note)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 4)
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
      Button(role: .destructive) {
        store.delete(note)
      } label: {
        Label("Delete", systemImage: "trash")
      }
      .accessibilityLabel("Delete \(note.title)")
    }
  }
}

private struct TranscriptSummary: View {
  @EnvironmentObject private var store: VoiceNoteStore
  let note: VoiceNote
  
  var body: some View {
    if store.transcribingNoteIDs.contains(note.id) {
      Label("Transcribing", systemImage: "waveform.and.magnifyingglass")
        .font(.caption)
        .foregroundStyle(.secondary)
    } else if let transcript = note.transcript, !transcript.isEmpty {
      Text(transcript)
        .font(.subheadline)
        .foregroundStyle(.primary)
        .lineLimit(2)
        .padding(.top, 4)
    } else {
      Text("No transcription available")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }
  }
}


#Preview {
  VoiceNoteRow(note: VoiceNoteStore.mock.notes[0])
    .environmentObject(VoiceNoteStore.mock)
}
