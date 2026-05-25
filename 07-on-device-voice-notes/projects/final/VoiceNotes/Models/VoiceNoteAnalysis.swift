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
import FoundationModels

@Generable(description: "A concise analysis of a transcribed voice note.")
struct NoteAnalysis {
  @Guide(description: "A concise title of a few words that summarizes the note contents.")
  let title: String

  @Guide(description: "A two to three sentence summary of the voice note.")
  let summary: String

  @Guide(description: "Up to five short lowercase topic tags.", .count(1...5))
  let tags: [String]

  @Guide(description: "People referenced in the note..")
  let people: [String]

  @Guide(description: "Specific action items or tasks mentioned in the note.")
  let actionItems: [NoteActionItem]
}

@Generable(description: "An actionable item or task extracted from the voice note.")
struct NoteActionItem: Identifiable, Codable, Equatable {
  let id = UUID()
  @Guide(description: "The task or action to be completed.")
  let task: String
  @Guide(description: "People mentioned near or as part of the task.")
  let person: [String]
  
  private enum CodingKeys: String, CodingKey {
    case task
    case person
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    task = try container.decode(String.self, forKey: .task)
    person = try container.decode(Array<String>.self, forKey: .person)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(task, forKey: .task)
    try container.encode(person, forKey: .person)
  }
}
