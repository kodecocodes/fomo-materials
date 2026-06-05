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

struct VoiceNoteTasksSection: View {
  var actionItems: [NoteActionItem]
  
  var body: some View {
    if !actionItems.isEmpty {
      VStack(alignment: .leading, spacing: 12) {
        Text("Action Items")
          .font(.headline)
        VStack(spacing: 8) {
          ForEach(actionItems) { task in
            ActionItemRow(task: task)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
    }
  }
}

struct ActionItemRow: View {
  @EnvironmentObject private var store: VoiceNoteStore
  let task: NoteActionItem
  
  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Button {
        withAnimation {
          store.updateTaskCompletion(!task.isCompleted, for: task.id)
        }
      } label: {
        Image(systemName: task.isCompleted ?
              "checkmark.circle.fill" : "circle"
        )
        .font(.body)
        .foregroundStyle(.secondary)
        .frame(width: 20, height: 20)
        .padding(.top, 1)
      }
      VStack(alignment: .leading, spacing: 4) {
        Text(task.task)
          .font(.body)
          .strikethrough(task.isCompleted)
          .textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
        if !task.people.isEmpty {
          ForEach(task.people, id: \.self) { person in
            Label(person, systemImage: "person")
              .font(.caption)
              .strikethrough(task.isCompleted)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(
      Color(.secondarySystemGroupedBackground),
      in: RoundedRectangle(cornerRadius: 10)
    )
  }
}
