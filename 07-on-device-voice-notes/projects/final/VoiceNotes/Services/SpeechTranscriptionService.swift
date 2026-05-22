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

import AVFoundation
import Foundation
import Speech

enum SpeechTranscriptionError: LocalizedError {
  case unavailable
  case authorizationDenied
  case unsupportedLocale
  case emptyResult

  var errorDescription: String? {
    switch self {
    case .unavailable:
      "SpeechTranscriber is not available on this device."
    case .authorizationDenied:
      "Speech recognition access is needed to transcribe voice notes."
    case .unsupportedLocale:
      "SpeechTranscriber does not support the current language."
    case .emptyResult:
      "No speech was detected in this recording."
    }
  }
}

struct SpeechTranscriptionService {
  // 1
  func transcribeAudio(at url: URL) async throws -> String {
    // 2
    guard await requestSpeechAuthorization() else {
      throw SpeechTranscriptionError.authorizationDenied
    }
    
    // 3
    return try await transcribeWithSpeechTranscriber(at: url)
  }
  
  private func requestSpeechAuthorization() async -> Bool {
    await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { status in
        continuation.resume(returning: status == .authorized)
      }
    }
  }
  
  private func transcribeWithSpeechTranscriber(at url: URL) async throws -> String {
    guard SpeechTranscriber.isAvailable else {
      throw SpeechTranscriptionError.unavailable
    }
    
    guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: .current) else {
      throw SpeechTranscriptionError.unsupportedLocale
    }
    
    let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
    let modules: [any SpeechModule] = [transcriber]
    try await prepareAssets(for: modules)

    // 1
    let audioFile = try AVAudioFile(forReading: url)
    // 2
    let resultsTask = Task {
      // 3
      var finalText = ""

      // 4
      for try await result in transcriber.results {
        // 5
        guard result.isFinal else { continue }
        // 6
        let text = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        // 7
        guard !text.isEmpty else { continue }

        // 8
        finalText += " " + text
      }

      // 9
      return finalText
    }
    
    // 1
    let analyzer = SpeechAnalyzer(modules: modules)
    // 2
    try await analyzer.start(inputAudioFile: audioFile, finishAfterFile: true)
    // 3
    let transcript = try await resultsTask.value.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !transcript.isEmpty else {
      throw SpeechTranscriptionError.emptyResult
    }

    return transcript
  }
  
  private func prepareAssets(for modules: [any SpeechModule]) async throws {
    switch await AssetInventory.status(forModules: modules) {
    // 1
    case .installed:
      return
    // 2
    case .downloading:
      guard let request = try await AssetInventory.assetInstallationRequest(supporting: modules) else {
        throw SpeechTranscriptionError.unavailable
      }
      try await request.downloadAndInstall()
    // 3
    case .supported:
      guard let request = try await AssetInventory.assetInstallationRequest(supporting: modules) else {
        throw SpeechTranscriptionError.unavailable
      }
      try await request.downloadAndInstall()
    // 4
    case .unsupported:
      throw SpeechTranscriptionError.unavailable
    @unknown default:
      throw SpeechTranscriptionError.unavailable
    }
  }
}
