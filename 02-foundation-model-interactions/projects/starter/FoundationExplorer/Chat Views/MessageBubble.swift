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

struct MessageBubble: View {
  let message: Message
  
  var bubbleColor: Color {
    switch message.type {
    case .prompt:
      return .blue
      
    case .fullResponse:
      return .gray.mix(with: .white, by: 0.4)

    case .error:
      return .red
    }
  }
  
  var textColor: Color {
    switch message.type {
    case .prompt:
      return .white
      
    case .fullResponse:
      return .primary

    case .error:
      return .white
    }
  }
    
  var body: some View {
    HStack {
      if message.type == .prompt {
        Spacer(minLength: 60)
      }

      VStack(alignment: message.type == .prompt ? .trailing : .leading, spacing: 4) {
        Text(LocalizedStringKey(message.text))
          .font(.body)
          .foregroundColor(textColor)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 20)
              .fill(bubbleColor)
          )
        Text(message.timestamp, style: .time)
          .font(.caption2)
          .foregroundColor(.secondary)
          .padding(.horizontal, 4)
      }

      if message.type != .prompt {
        Spacer(minLength: 60)
      }
    }
    .contextMenu {
      Group {
        Button {
          UIPasteboard.general.string = message.text
        } label: {
          Text("Copy")
        }
      }
    }
    .transition(.asymmetric(
      insertion: .move(edge: message.type == .prompt ? .trailing : .leading)
        .combined(with: .opacity),
      removal: .opacity
    ))
  }
}

#Preview {
  MessageBubble(
    message: Message(
      id: UUID(),
      text: "Prompt",
      type: .prompt,
      timestamp: Date.now
    )
  )
  MessageBubble(
    message: Message(
      id: UUID(),
      text: "Full Response",
      type: .fullResponse,
      timestamp: Date.now
    )
  )
}
