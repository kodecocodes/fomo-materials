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

enum NoteAnalysisError: LocalizedError {
  case missingTranscript
  case transcriptTooLarge

  var errorDescription: String? {
    switch self {
    case .missingTranscript:
      "No transcript is available to analyze."
    case .transcriptTooLarge:
      "This transcript is too long for the current model."
    }
  }
}

struct NoteAnalysisService {
  private func fitsInContext(_ prompt: String) async -> Bool {
    let tokenLength: Int

    // 1
    if #available(iOS 26.4, *) {
      // 2
      let promptCalc = try? await SystemLanguageModel.default.tokenCount(for: prompt)
      if let promptCalc = promptCalc {
        tokenLength = promptCalc
      } else {
        tokenLength = prompt.count * 3 / 4
      }
    } else {
      // 3
      tokenLength = prompt.count * 3 / 4
    }
    
    // 4
    return tokenLength < SystemLanguageModel.default.contextSize * 3 / 4
  }
  
  func analyze(transcript: String) async throws -> NoteAnalysis {
    // 1
    guard !transcript.isEmpty else {
      throw NoteAnalysisError.missingTranscript
    }

    // 2
    let session = LanguageModelSession()
    let prompt = """
      Analyze the following voice note transcription.

      Create:
      - A concise title of a few words
      - A two to three sentence summary focused on the overall topic and key points.
      - Up to five short lowercase tags, each one up to three words.
      - Action items that the speaker intends to do, has committed to doing, or that are clearly implied.
      - A list of people mentioned in the note.

      Do not invent details, deadlines, assignees, or people.
      If no action items are present, return an empty actionItems array.
      If no people are mentioned, return and empty people array.

      Transcription: \(transcript)
      """

    // 3
    guard await fitsInContext(prompt) else {
      throw NoteAnalysisError.transcriptTooLarge
    }

    // 4
    let response = try await session.respond(to: prompt, generating: NoteAnalysis.self)
    return response.content
  }
}
