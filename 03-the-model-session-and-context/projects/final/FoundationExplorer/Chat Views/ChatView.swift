/// Copyright (c) 2025 Kodeco Inc.
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
import FoundationModels

struct ChatView: View {
  @State private var promptText = ""
  @State private var messages: [Message] = []
  @FocusState private var isTextFieldFocused: Bool
  @State private var session = LanguageModelSession()
  @State private var confirmClear: Bool = false
  private var contextWindow = SystemLanguageModel.default.contextSize
  @State private var contextWindowSize: Int?
  @State private var promptSettings =
  PromptSettings(
    instructions: nil,
    temperature: nil,
    sampling: SamplingOptions(type: .system, threshold: 0.33, top: 10)
  )
  @State private var showSettings = false

  @ToolbarContentBuilder private var appToolbar: some ToolbarContent {
    ToolbarSpacer(.flexible, placement: .bottomBar)
    ToolbarItem(placement: .bottomBar) {
      Button("Settings", systemImage: "gear") {
        showSettings = true
      }
    }
    ToolbarItem(placement: .bottomBar) {
      Button("Clear", systemImage: "xmark.circle.fill") {
        confirmClear = true
      }
      .tint(.red)
      .confirmationDialog(
        "Are you sure you want to delete the chat history?",
        isPresented: $confirmClear
      ) {
        Button("Delete Chat History", role: .destructive) {
          resetChatHistory()
        }
      }
    }
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Instructions
        if messages.isEmpty {
          Text("Welcome to Foundation Explorer. Enter a message to begin interacting with the Foundation Model.")
            .font(.title2)
        }
        // Show messages
        ScrollViewReader { proxy in
          ScrollView {
            LazyVStack(spacing: 12) {
              ForEach(messages) { message in
                MessageBubble(message: message)
                  .id(message.id)
              }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            if session.isResponding {
              TypingIndicator()
                .transition(.scale)
            }
          }
          .onChange(of: messages.count) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
              proxy.scrollTo(messages.last?.id, anchor: .bottom)
            }
          }
          .onChange(of: messages.last?.text) { _, _ in
            withAnimation(.easeInOut(duration: 0.1)) {
              proxy.scrollTo(messages.last?.id, anchor: .bottom)
            }
          }
        }
        // Message input
        MessageInputView(
          messageText: $promptText,
          isTextFieldFocused: $isTextFieldFocused,
          sendAction: sendPrompt
        )
        .disabled(session.isResponding)
        if let tokenCount = contextWindowSize {
          Text("Context Window: \(tokenCount)/\(contextWindow) tokens.")
            .font(.footnote)
        } else {
          Text("Context Window: \(contextWindow) tokens.")
            .font(.footnote)
        }
      }
      .navigationTitle("Foundation Explorer")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        appToolbar
      }
      .sheet(isPresented: $showSettings) {
        ConfigurationView(settings: $promptSettings)
      }
      .onChange(of: promptSettings.instructions) {
        Task {
          resetChatHistory()
          await updatedContextWindowUsed()
        }
      }
    }
  }

  private func addMessage(_ message: String, type: MessageType, animate: Bool = true) {
    Task {
      var tokens: Int?
    
      if type == .prompt || type == .fullResponse {
          tokens = await tokenCount(for: message)
      } else {
        tokens = nil
      }
      
      let newMessage = Message(
        id: UUID(),
        text: message,
        type: type,
        timestamp: Date(),
        tokens: tokens
      )

      if animate {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
          messages.append(newMessage)
        }
      } else {
        messages.append(newMessage)
      }
    }
  }

  private func sendPrompt() async {
    guard !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    addMessage(promptText, type: .prompt)

    let samplingOptions = promptSettings.sampling
    var sampling: GenerationOptions.SamplingMode?

    // 1
    switch samplingOptions.type {
    // 2
    case .system:
      sampling = nil
    // 3
    case .greedy:
      sampling = GenerationOptions.SamplingMode.greedy
    // 4
    case .top:
      sampling = GenerationOptions.SamplingMode.random(
        top: samplingOptions.top,
        seed: samplingOptions.seed
      )
    // 5
    case .threshold:
      sampling = GenerationOptions.SamplingMode.random(
        probabilityThreshold: samplingOptions.threshold,
        seed: samplingOptions.seed
      )
    }
    let options = GenerationOptions(
      sampling: sampling,
      temperature: promptSettings.temperature
    )
    let stream = session.streamResponse(to: promptText, options: options)
    promptText = ""

    do {
      for try await partialResponse in stream {
        if messages.last?.type != .partialResponse {
          addMessage(
            partialResponse.content,
            type: .partialResponse
          )
        } else {
          messages[messages.count - 1].text = partialResponse.content
        }
      }

      let lastIndex = messages.count - 1
      messages[lastIndex].type = .fullResponse
      messages[lastIndex].timestamp = Date.now
      messages[lastIndex].tokens = await tokenCount(for: messages[lastIndex].text)
    }
    catch LanguageModelSession.GenerationError.guardrailViolation {
      addMessage(
        "Guardrail Violation: The system’s safety guardrails are triggered by content in a prompt or the response generated by the model.",
        type: .error
      )
    }
    catch LanguageModelSession.GenerationError.exceededContextWindowSize {
      addMessage(
        "Context Windows Length of \(contextWindow) tokens has been exceeded.",
        type: .error
      )
    }
    catch {
      addMessage(error.localizedDescription, type: .error)
    }
    await updatedContextWindowUsed()
  }

  private func resetChatHistory() {
    messages = []

    if let instructions = promptSettings.instructions {
      session = LanguageModelSession(instructions: instructions)
    } else {
      session = LanguageModelSession()
    }
  }
  
  private func updatedContextWindowUsed() async {
    guard #available(iOS 26.4, *) else {
      contextWindowSize = nil
      return
    }
    contextWindowSize = try? await SystemLanguageModel.default.tokenCount(for: session.transcript)
  }
  
  private func tokenCount(for text: String) async -> Int? {
    guard #available(iOS 26.4, *) else { return nil }
    return try? await SystemLanguageModel.default.tokenCount(for: Prompt(text))
  }
}


// Preview
struct ChatView_Previews: PreviewProvider {
  static var previews: some View {
    ChatView()
  }
}
