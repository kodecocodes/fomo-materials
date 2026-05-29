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

struct SeedVoiceNote {
  let title: String
  let bundledFilename: String
  let duration: TimeInterval
  let transcript: String?

  init(
    title: String,
    bundledFilename: String,
    duration: TimeInterval,
    transcript: String? = nil,
  ) {
    self.title = title
    self.bundledFilename = bundledFilename
    self.duration = duration
    self.transcript = transcript
  }
}

extension VoiceNoteRepository {
  private var sampleSeedKey: String {
    "didSeedSampleVoiceNotes"
  }

  func seedNotesIfNeeded() -> [VoiceNote] {
    let existingNotes = loadNotes()

    guard !UserDefaults.standard.bool(forKey: sampleSeedKey) else {
      return existingNotes
    }

    guard existingNotes.isEmpty else {
      UserDefaults.standard.set(true, forKey: sampleSeedKey)
      return existingNotes
    }

    let notes = addSampleNotes(to: existingNotes)
    UserDefaults.standard.set(true, forKey: sampleSeedKey)
    return notes
  }

  func addSampleNotes(to existingNotes: [VoiceNote]? = nil) -> [VoiceNote] {
    var notes = existingNotes ?? loadNotes()

    for seed in SeedVoiceNote.samples {
      guard !notes.contains(where: { $0.filename == seed.bundledFilename }) else {
        continue
      }

      guard let sourceURL = Bundle.main.url(
        forResource: seed.bundledFilename,
        withExtension: nil
      ) else {
        continue
      }

      let destinationURL = recordingsDirectory.appendingPathComponent(seed.bundledFilename)

      do {
        if FileManager.default.fileExists(atPath: destinationURL.path) {
          try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        let note = VoiceNote(
          title: seed.title,
          duration: seed.duration,
          filename: seed.bundledFilename,
          transcript: seed.transcript
        )
        notes.insert(note, at: 0)
      } catch {
        continue
      }
    }

    saveNotes(notes)
    return notes
  }

  #if DEBUG
  func clearSampleSeedFlagForTesting() {
    UserDefaults.standard.removeObject(forKey: sampleSeedKey)
  }

  func resetSampleNotesForTesting(from existingNotes: [VoiceNote]) -> [VoiceNote] {
    clearSampleSeedFlagForTesting()

    let sampleFilenames = Set(SeedVoiceNote.samples.map(\.bundledFilename))
    let notes = existingNotes.filter { note in
      guard sampleFilenames.contains(note.filename) else {
        return true
      }

      deleteRecording(for: note)
      return false
    }

    let seededNotes = addSampleNotes(to: notes)
    UserDefaults.standard.set(true, forKey: sampleSeedKey)
    return seededNotes
  }
  #endif
}

extension SeedVoiceNote {
  static let samples = [
    SeedVoiceNote(
      title: "Launch checklist",
      bundledFilename: "sample-recording-1.m4a",
      duration: 15.8
    ),
    SeedVoiceNote(
      title: "Project follow-up",
      bundledFilename: "sample-recording-2.m4a",
      duration: 14.1
    ),
    SeedVoiceNote(
      title: "Design review",
      bundledFilename: "sample-recording-3.m4a",
      duration: 15.4
    )
  ]
}
