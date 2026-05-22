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

@MainActor
final class VoiceNoteStore: ObservableObject {
  @Published private(set) var notes: [VoiceNote] = []
  @Published private(set) var isRecording = false
  @Published private(set) var elapsedTime: TimeInterval = 0
  @Published private(set) var playingNoteID: VoiceNote.ID?
  @Published private(set) var playbackNoteID: VoiceNote.ID?
  @Published private(set) var playbackTime: TimeInterval = 0
  @Published private(set) var transcribingNoteIDs: Set<VoiceNote.ID> = []
  @Published private(set) var analyzingNoteIDs: Set<VoiceNote.ID> = []
  @Published var permissionMessage: String?

  private let repository = VoiceNoteRepository()
  private let recorder = VoiceNoteRecorder()
  private let player = VoiceNotePlayer()
  // private let transcriptionService = SpeechTranscriptionService()
  // private let analysisService = NoteAnalysisService()

  private var recordingTimer: Timer?
  private var playbackTimer: Timer?
  private var recordingStartDate: Date?
  private var activeRecordingURL: URL?
  
  #if DEBUG
    convenience init(mockNotes: [VoiceNote]) {
      self.init()
      self.notes = mockNotes
    }
  #endif

  init() {
    notes = repository.seedNotesIfNeeded()
    player.didFinishPlaying = { [weak self] in
      Task { @MainActor in
        self?.finishPlayback()
      }
    }
  }

  var hasNotes: Bool {
    !notes.isEmpty
  }

  func startRecording() async {
    guard !isRecording else { return }

    let hasPermission = await requestMicrophonePermission()
    guard hasPermission else {
      permissionMessage = "Microphone access is needed to record voice notes."
      return
    }

    stopPlayback()

    do {
      let url = try recorder.startRecording(in: repository.recordingsDirectory)
      activeRecordingURL = url
      recordingStartDate = .now
      elapsedTime = 0
      isRecording = true
      permissionMessage = nil
      startTimer()
    } catch {
      permissionMessage = "Recording could not start. Please try again."
    }
  }

  func stopRecording() {
    guard isRecording else { return }

    stopTimer()

    let duration = elapsedTime
    guard let url = recorder.stopRecording() ?? activeRecordingURL else { return }

    activeRecordingURL = nil
    recordingStartDate = nil
    elapsedTime = 0
    isRecording = false

    guard duration >= 0.5 else {
      repository.deleteRecording(at: url)
      return
    }

    let note = VoiceNote(
      title: defaultTitle(for: .now),
      duration: duration,
      filename: url.lastPathComponent
    )
    notes.insert(note, at: 0)
    saveNotes()
  }

  func togglePlayback(for note: VoiceNote) {
    if playingNoteID == note.id {
      pausePlayback()
      return
    }

    stopRecording()

    if playbackNoteID == note.id, player.isPaused {
      player.resume()
      playingNoteID = note.id
      startPlaybackTimer()
      return
    }

    stopPlayback()

    do {
      try player.play(url: url(for: note))
      playbackNoteID = note.id
      playbackTime = player.currentTime
      playingNoteID = note.id
      startPlaybackTimer()
    } catch {
      permissionMessage = "This voice note could not be played."
    }
  }

  func delete(_ note: VoiceNote) {
    if playbackNoteID == note.id {
      stopPlayback()
    }

    notes.removeAll { $0.id == note.id }
    transcribingNoteIDs.remove(note.id)
    analyzingNoteIDs.remove(note.id)
    repository.deleteRecording(for: note)
    saveNotes()
  }

  func seekPlayback(for note: VoiceNote, to time: TimeInterval) {
    let clampedTime = min(max(0, time), note.duration)

    guard playbackNoteID == note.id else {
      playbackTime = clampedTime
      return
    }

    player.currentTime = clampedTime
    playbackTime = clampedTime
  }

  func url(for note: VoiceNote) -> URL {
    repository.url(for: note)
  }

  func note(withID noteID: VoiceNote.ID) -> VoiceNote? {
    notes.first { $0.id == noteID }
  }

  #if DEBUG
  func clearSampleSeedFlagForTesting() {
    repository.clearSampleSeedFlagForTesting()
  }

  func resetSampleNotesForTesting() {
    stopPlayback()
    transcribingNoteIDs.removeAll()
    analyzingNoteIDs.removeAll()
    notes = repository.resetSampleNotesForTesting(from: notes)
  }
  #endif

  private func updateTranscript(_ transcript: String, for noteID: VoiceNote.ID) {
    guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }
    notes[index].transcript = transcript
    saveNotes()
  }

  private func saveNotes() {
    repository.saveNotes(notes)
  }

  private func startTimer() {
    stopTimer()
    recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      Task { @MainActor in
        guard let self, let recordingStartDate = self.recordingStartDate else { return }
        self.elapsedTime = Date().timeIntervalSince(recordingStartDate)
      }
    }
  }

  private func stopTimer() {
    recordingTimer?.invalidate()
    recordingTimer = nil
  }

  private func startPlaybackTimer() {
    stopPlaybackTimer()
    playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        self.playbackTime = self.player.currentTime
      }
    }
  }

  private func stopPlaybackTimer() {
    playbackTimer?.invalidate()
    playbackTimer = nil
  }

  private func pausePlayback() {
    player.pause()
    playbackTime = player.currentTime
    playingNoteID = nil
    stopPlaybackTimer()
  }

  private func stopPlayback() {
    player.stop()
    finishPlayback()
  }

  private func finishPlayback() {
    playingNoteID = nil
    playbackNoteID = nil
    playbackTime = 0
    stopPlaybackTimer()
  }

  private func requestMicrophonePermission() async -> Bool {
    #if os(iOS)
    await withCheckedContinuation { continuation in
      AVAudioApplication.requestRecordPermission { granted in
        continuation.resume(returning: granted)
      }
    }
    #else
    true
    #endif
  }

  private func defaultTitle(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return "Voice Note \(formatter.string(from: date))"
  }
}

#if DEBUG
extension VoiceNoteStore {
  static var mock: VoiceNoteStore {
    VoiceNoteStore(mockNotes: [.mockWithAnalysis, .mockWithTranscript, .mock])
  }
}
#endif
