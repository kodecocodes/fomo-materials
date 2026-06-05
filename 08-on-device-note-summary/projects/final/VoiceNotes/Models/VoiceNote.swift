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

import Foundation

struct VoiceNote: Identifiable, Codable, Equatable {
  let id: UUID
  var title: String
  let createdAt: Date
  var duration: TimeInterval
  let filename: String
  var transcript: String?
  var summary: String?
  var tags = [String]()
  var people = [String]()
  var actionItems = [NoteActionItem]()

  init(
    id: UUID = UUID(),
    title: String,
    createdAt: Date = .now,
    duration: TimeInterval,
    filename: String,
    transcript: String? = nil
  ) {
    self.id = id
    self.title = title
    self.createdAt = createdAt
    self.duration = duration
    self.filename = filename
    self.transcript = transcript
  }

  func matchesPeople(_ text: String) -> Bool {
    // 1
    people.contains { $0.localizedStandardContains(text) } ||
    // 2
    actionItems.contains {
      $0.people.contains { $0.localizedStandardContains(text) }
    }
  }

  func matchesActionItems(_ text: String) -> Bool {
    actionItems.contains {
      $0.task.localizedStandardContains(text) ||
      $0.people.contains { $0.localizedStandardContains(text) }
    }
  }

  func matchesTranscript(_ text: String) -> Bool {
    transcript?.localizedStandardContains(text) == true
  }

  func anyFieldMatches(_ text: String) -> Bool {
    title.localizedStandardContains(text) ||
    matchesTranscript(text) ||
    summary?.localizedStandardContains(text) == true ||
    matchesPeople(text) ||
    matchesActionItems(text)
  }
}

struct NoteActionItem: Identifiable, Codable, Equatable {
  let id: UUID
  var isCompleted: Bool
  let task: String
  let people: [String]

  init(from generatedItem: GeneratedNoteActionItem) {
    id = UUID()
    isCompleted = generatedItem.isCompleted
    task = generatedItem.task
    people = generatedItem.people
  }
}

#if DEBUG
extension VoiceNote {
    static let mock = VoiceNote(
        title: "Weekly planning",
        createdAt: .now,
        duration: 183,
        filename: "mock.m4a"
    )

    static let mockWithTranscript = VoiceNote(
        title: "Project ideas",
        createdAt: .now,
        duration: 94,
        filename: "mock2.m4a",
        transcript: """
          Had the call with Marcus and the design team this morning. We need to get the revised mockups over to the client by Thursday. Marcus is going to handle the export, I need to write up the meeting notes and send them to Sarah. Overall I think the direction is good but the color palette still needs work.
          """
    )

    static let mockWithAnalysis = VoiceNote(
        title: "Launch checklist",
        createdAt: .now,
        duration: 126,
        filename: "mock3.m4a",
        transcript: """
          Before the beta goes out, I need to ask Maya to review the onboarding copy, follow up with Jordan about the icon export, and make sure the settings screen includes the new privacy explanation. The biggest thing is keeping the first-run experience short and clear.
          """
    )
}
#endif
