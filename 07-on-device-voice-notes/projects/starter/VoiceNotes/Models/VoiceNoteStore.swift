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
final class VoiceNoteStore: NSObject, ObservableObject {
  @Published private(set) var notes: [VoiceNote] = []
  @Published private(set) var isRecording = false
  @Published private(set) var elapsedTime: TimeInterval = 0
  @Published private(set) var playingNoteID: VoiceNote.ID?
  @Published private(set) var playbackNoteID: VoiceNote.ID?
  @Published private(set) var playbackTime: TimeInterval = 0
  @Published private(set) var transcribingNoteIDs: Set<VoiceNote.ID> = []
  @Published var permissionMessage: String?

  private let transcriptionService = SpeechTranscriptionService()
  private var recorder: AVAudioRecorder?
  private var player: AVAudioPlayer?
  private var recordingTimer: Timer?
  private var playbackTimer: Timer?
  private var recordingStartDate: Date?
  private var activeRecordingURL: URL?

  private let metadataURL: URL
  private let recordingsDirectory: URL
  
  #if DEBUG
    convenience init(mockNotes: [VoiceNote]) {
      self.init()
      self.notes = mockNotes
    }
  #endif

  override init() {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    recordingsDirectory = documents.appendingPathComponent("Recordings", isDirectory: true)
    metadataURL = documents.appendingPathComponent("VoiceNotes.json")

    super.init()
    createRecordingsDirectory()
    loadNotes()
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
    configureAudioSessionForRecording()

    let id = UUID()
    let url = recordingsDirectory.appendingPathComponent("\(id.uuidString).m4a")
    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44_100,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    do {
      let recorder = try AVAudioRecorder(url: url, settings: settings)
      recorder.delegate = self
      recorder.record()

      self.recorder = recorder
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
    guard isRecording, let recorder else { return }

    recorder.stop()
    stopTimer()

    let duration = elapsedTime
    let url = recorder.url
    self.recorder = nil
    activeRecordingURL = nil
    recordingStartDate = nil
    elapsedTime = 0
    isRecording = false

    guard duration >= 0.5 else {
      try? FileManager.default.removeItem(at: url)
      return
    }

    let note = VoiceNote(
      title: defaultTitle(for: .now),
      duration: duration,
      filename: url.lastPathComponent
    )
    notes.insert(note, at: 0)
    saveNotes()

    Task {
      await transcribe(note)
    }
  }

  func togglePlayback(for note: VoiceNote) {
    if playingNoteID == note.id {
      pausePlayback()
      return
    }

    stopRecording()
    configureAudioSessionForPlayback()

    if playbackNoteID == note.id, let player {
      player.play()
      playingNoteID = note.id
      startPlaybackTimer()
      return
    }

    stopPlayback()

    do {
      let player = try AVAudioPlayer(contentsOf: url(for: note))
      player.delegate = self
      player.prepareToPlay()
      player.play()
      self.player = player
      playbackNoteID = note.id
      playbackTime = player.currentTime
      playingNoteID = note.id
      startPlaybackTimer()
    } catch {
      permissionMessage = "This voice note could not be played."
    }
  }

  func delete(_ note: VoiceNote) {
    if playingNoteID == note.id {
      stopPlayback()
    }

    notes.removeAll { $0.id == note.id }
    transcribingNoteIDs.remove(note.id)
    try? FileManager.default.removeItem(at: url(for: note))
    saveNotes()
  }

  func seekPlayback(for note: VoiceNote, to time: TimeInterval) {
    let clampedTime = min(max(0, time), note.duration)

    guard playbackNoteID == note.id, let player else {
      playbackTime = clampedTime
      return
    }

    player.currentTime = clampedTime
    playbackTime = clampedTime
  }

  func transcribe(_ note: VoiceNote) async {
    guard note.transcript?.isEmpty != false else { return }
    guard !transcribingNoteIDs.contains(note.id) else { return }

    transcribingNoteIDs.insert(note.id)

    do {
      let transcript = try await transcriptionService.transcribeAudio(at: url(for: note))
      updateTranscript(transcript, for: note.id)
    } catch {
      permissionMessage = (error as? LocalizedError)?.errorDescription
        ?? "This voice note could not be transcribed."
    }

    transcribingNoteIDs.remove(note.id)
  }

  func url(for note: VoiceNote) -> URL {
    recordingsDirectory.appendingPathComponent(note.filename)
  }

  func note(withID noteID: VoiceNote.ID) -> VoiceNote? {
    notes.first { $0.id == noteID }
  }

  private func updateTranscript(_ transcript: String, for noteID: VoiceNote.ID) {
    guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }
    notes[index].transcript = transcript
    saveNotes()
  }

  private func createRecordingsDirectory() {
    try? FileManager.default.createDirectory(
      at: recordingsDirectory,
      withIntermediateDirectories: true
    )
  }

  private func loadNotes() {
    guard let data = try? Data(contentsOf: metadataURL) else { return }
    notes = (try? JSONDecoder().decode([VoiceNote].self, from: data)) ?? []
  }

  private func saveNotes() {
    guard let data = try? JSONEncoder().encode(notes) else { return }
    try? data.write(to: metadataURL, options: [.atomic])
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
        guard let self, let player = self.player else { return }
        self.playbackTime = player.currentTime
      }
    }
  }

  private func stopPlaybackTimer() {
    playbackTimer?.invalidate()
    playbackTimer = nil
  }

  private func pausePlayback() {
    player?.pause()
    if let player {
      playbackTime = player.currentTime
    }
    playingNoteID = nil
    stopPlaybackTimer()
  }

  private func stopPlayback() {
    player?.stop()
    player = nil
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

  private func configureAudioSessionForRecording() {
    #if os(iOS)
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
    try? session.setActive(true)
    #endif
  }

  private func configureAudioSessionForPlayback() {
    #if os(iOS)
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default)
    try? session.setActive(true)
    #endif
  }

  private func defaultTitle(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return "Voice Note \(formatter.string(from: date))"
  }
}

extension VoiceNoteStore: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
  nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    Task { @MainActor in
      self.playingNoteID = nil
      self.playbackNoteID = nil
      self.playbackTime = 0
      self.player = nil
      self.stopPlaybackTimer()
    }
  }
}

#if DEBUG
extension VoiceNoteStore {
  static var mock: VoiceNoteStore {
    VoiceNoteStore(mockNotes: [.mock, .mockWithTranscript])
  }
}
#endif
