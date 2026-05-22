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

struct VoiceNoteRepository {
  let recordingsDirectory: URL
  private let metadataURL: URL

  init() {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    recordingsDirectory = documents.appendingPathComponent("Recordings", isDirectory: true)
    metadataURL = documents.appendingPathComponent("VoiceNotes.json")

    try? FileManager.default.createDirectory(
      at: recordingsDirectory,
      withIntermediateDirectories: true
    )
  }

  func loadNotes() -> [VoiceNote] {
    guard let data = try? Data(contentsOf: metadataURL) else { return [] }
    return (try? JSONDecoder().decode([VoiceNote].self, from: data)) ?? []
  }

  func saveNotes(_ notes: [VoiceNote]) {
    guard let data = try? JSONEncoder().encode(notes) else { return }
    try? data.write(to: metadataURL, options: [.atomic])
  }

  func url(for note: VoiceNote) -> URL {
    recordingsDirectory.appendingPathComponent(note.filename)
  }

  func deleteRecording(for note: VoiceNote) {
    try? FileManager.default.removeItem(at: url(for: note))
  }

  func deleteRecording(at url: URL) {
    try? FileManager.default.removeItem(at: url)
  }
}
