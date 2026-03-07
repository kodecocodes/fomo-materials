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

struct ChatView: View {
  @State private var promptText = ""
  @State private var messages: [Message] = []
  @FocusState private var isTextFieldFocused: Bool

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Instuctions
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
      }
      .navigationTitle("Foundation Explorer")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private func resetChatHistory() async {
    messages = []
  }

  private func addMessage(_ message: String, type: MessageType, animate: Bool = true) {
    let newMessage = Message(
      id: UUID(),
      text: message,
      type: type,
      timestamp: Date()
    )

    if animate {
      withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
        messages.append(newMessage)
      }
    } else {
      messages.append(newMessage)
    }
  }

  private func sendPrompt() async {
    guard !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    // Append prompt to messages
    addMessage(promptText, type: .prompt)

    // Clear prompt
    addMessage(promptText, type: .fullResponse)
    promptText = ""
  }
}


// Preview
struct ChatView_Previews: PreviewProvider {
  static var previews: some View {
    ChatView()
  }
}
