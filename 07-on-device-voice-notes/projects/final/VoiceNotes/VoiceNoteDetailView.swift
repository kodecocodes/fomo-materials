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

struct VoiceNoteDetailView: View {
  @EnvironmentObject private var store: VoiceNoteStore
  @Environment(\.dismiss) private var dismiss
  @State private var isShowingDeleteConfirmation = false

  let noteID: VoiceNote.ID

  var body: some View {
    Group {
      if let note = store.note(withID: noteID) {
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            VoiceNoteDetailHeader(note: note)
            VoiceNoteTranscriptSection(note: note)
            VoiceNoteTextSection(text: note.summary, title: "Summary")
            VoiceNoteTagsSection(tags: note.tags, title: "Tags")
            VoiceNoteTagsSection(tags: note.people, title: "People")
            VoiceNoteTasksSection(actionItems: note.actionItems)
          }
          .padding(16)
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          ToolbarItemGroup(placement: .topBarTrailing) {
            // 1
            if note.transcript == nil {
              Button {
                // 2
                Task {
                  await store.transcribeRecording(note)
                }
              } label: {
                Image(systemName: "sparkles")
                  .accessibilityLabel("Produce Transcript")
              }
            // 3
            } else if let transcript = note.transcript {
              Button {
                // 4
                Task {
                  await store.performAnalysis(
                    transcript,
                    for: note.id
                  )
                }
              } label: {
                Image(systemName: "sparkles.2")
                  .accessibilityLabel("Perform Analysis")
              }
            }
            Button(role: .destructive) {
              isShowingDeleteConfirmation = true
            } label: {
              Image(systemName: "trash")
            }
            .accessibilityLabel("Delete \(note.title)")
          }
        }
        .confirmationDialog(
          "Delete Voice Note?",
          isPresented: $isShowingDeleteConfirmation,
          titleVisibility: .visible
        ) {
          Button("Delete", role: .destructive) {
            store.delete(note)
            dismiss()
          }

          Button("Cancel", role: .cancel) { }
        } message: {
          Text("This recording will be permanently removed.")
        }
      } else {
        ContentUnavailableView(
          "Voice Note Unavailable",
          systemImage: "waveform.slash",
          description: Text("This note may have been deleted.")
        )
      }
    }
  }
}

private struct VoiceNoteDetailHeader: View {
  let note: VoiceNote

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(note.createdAt.formatted(date: .complete, time: .shortened))
        .font(.subheadline)
        .foregroundStyle(.secondary)

      VoiceNotePlaybackControl(note: note)
    }
    .padding(16)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
  }
}

private struct VoiceNotePlaybackControl: View {
  @EnvironmentObject private var store: VoiceNoteStore
  let note: VoiceNote

  private var isActiveNote: Bool {
    store.playbackNoteID == note.id
  }

  private var isPlaying: Bool {
    store.playingNoteID == note.id
  }

  private var currentTime: TimeInterval {
    isActiveNote ? min(store.playbackTime, note.duration) : 0
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 16) {
        Button {
          store.togglePlayback(for: note)
        } label: {
          Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.title2.weight(.semibold))
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(Circle())
        .contentTransition(.symbolEffect(.replace))
        .accessibilityLabel(isPlaying ? "Pause \(note.title)" : "Play \(note.title)")

        VStack(alignment: .leading, spacing: 4) {
          if isPlaying {
            Label("Playing", systemImage: "speaker.wave.2.fill")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.tint)
          }

          Label(formattedTime(note.duration), systemImage: "clock")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }

      Slider(
        value: Binding(
          get: { currentTime },
          set: { store.seekPlayback(for: note, to: $0) }
        ),
        in: 0...max(note.duration, 0.1)
      )
      .disabled(!isActiveNote)
      .accessibilityLabel("Playback position")

      HStack {
        Text(formattedTime(currentTime))
        Spacer()
        Text("-\(formattedTime(note.duration - currentTime))")
      }
      .font(.caption.monospacedDigit())
      .foregroundStyle(.secondary)
    }
  }
}

private struct VoiceNoteTranscriptSection: View {
  @EnvironmentObject private var store: VoiceNoteStore
  let note: VoiceNote

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Transcript")
        .font(.headline)

      if store.transcribingNoteIDs.contains(note.id) {
        Label("Transcribing", systemImage: "waveform.and.magnifyingglass")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else if let transcript = note.transcript, !transcript.isEmpty {
        Text(transcript)
          .font(.body)
          .textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
      } else {
        VStack(alignment: .leading, spacing: 12) {
          Text("No transcript is available for this recording yet.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Button {
            Task {
              await store.transcribeRecording(note)
            }
          } label: {
            Label("Transcribe", systemImage: "text.bubble")
          }
          .buttonStyle(.borderedProminent)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
  }
}

private struct VoiceNoteTextSection: View {
  let text: String?
  let title: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)
      if let text = text {
        Text(text)
          .font(.body)
          .textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
  }
}

private struct VoiceNoteTagsSection: View {
  var tags: [String]
  var title: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)
      if !tags.isEmpty {
        FlowLayout(spacing: 8) {
          ForEach(tags, id: \.self) { tag in
            Text(tag)
              .font(.subheadline.weight(.medium))
              .foregroundStyle(.secondary)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color(.systemGray6), in: Capsule())
          }
        }
      }
    }
  }
}

private struct VoiceNoteTasksSection: View {
  var actionItems: [NoteActionItem]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Action Items")
        .font(.headline)
      VStack(spacing: 8) {
        if !actionItems.isEmpty {
          ForEach(actionItems) { task in
            ActionItemRow(task: task)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
  }
}

private struct ActionItemRow: View {
  let task: NoteActionItem
  
  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: "circle")
        .font(.body)
        .foregroundStyle(.secondary)
        .frame(width: 20, height: 20)
        .padding(.top, 1)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(task.task)
          .font(.body)
          .textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
        
        if !task.person.isEmpty {
          ForEach(task.person, id: \.self) { person in
            Label(person, systemImage: "person")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
  }
}

private extension VoiceNote {
  var hasTranscript: Bool {
    transcript?.isEmpty == false
  }
}

private struct FlowLayout: Layout {
  var spacing: CGFloat

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
  ) -> CGSize {
    let rows = rows(in: proposal.width ?? 0, subviews: subviews)
    return CGSize(
      width: proposal.width ?? rows.map(\.width).max() ?? 0,
      height: rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
    )
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
  ) {
    var y = bounds.minY

    for row in rows(in: bounds.width, subviews: subviews) {
      var x = bounds.minX

      for item in row.items {
        item.subview.place(
          at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
          proposal: ProposedViewSize(item.size)
        )
        x += item.size.width + spacing
      }

      y += row.height + spacing
    }
  }

  private func rows(in width: CGFloat, subviews: Subviews) -> [Row] {
    var rows: [Row] = []
    var currentRow = Row()

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      let nextWidth = currentRow.items.isEmpty
        ? size.width
        : currentRow.width + spacing + size.width

      if nextWidth > width, !currentRow.items.isEmpty {
        rows.append(currentRow)
        currentRow = Row()
      }

      currentRow.items.append(RowItem(subview: subview, size: size))
      currentRow.width = currentRow.items.isEmpty ? 0 : min(max(currentRow.width, nextWidth), width)
      currentRow.height = max(currentRow.height, size.height)
    }

    if !currentRow.items.isEmpty {
      rows.append(currentRow)
    }

    return rows
  }

  private struct Row {
    var items: [RowItem] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
  }

  private struct RowItem {
    let subview: LayoutSubview
    let size: CGSize
  }
}


#Preview {
  NavigationView {
    VoiceNoteDetailView(
      noteID: VoiceNoteStore.mock.notes[0].id
    )
    .environmentObject(VoiceNoteStore.mock)
  }
}
