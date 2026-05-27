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

import SwiftUI

struct VoiceNoteTagsSection: View {
  var tags: [String]
  var title: String

  var body: some View {
    if !tags.isEmpty {
      VStack(alignment: .leading, spacing: 12) {
        Text(title)
          .font(.headline)
        FlowLayout(spacing: 8) {
          ForEach(tags, id: \.self) { tag in
            Text(tag)
              .font(.subheadline.weight(.medium))
              .foregroundStyle(.secondary)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color(.systemGray6), in: Capsule())
          }
        }
      }
      .padding(16)
    }
  }
}

private struct FlowLayout: Layout {
  var spacing: CGFloat

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
  ) -> CGSize {
    let rows = rows(in: proposal.width ?? 0, subviews: subviews)
    return CGSize(
      width: proposal.width ?? rows.map(\.width).max() ?? 0,
      height: rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
    )
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
  ) {
    var y = bounds.minY

    for row in rows(in: bounds.width, subviews: subviews) {
      var x = bounds.minX

      for item in row.items {
        item.subview.place(
          at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
          proposal: ProposedViewSize(item.size)
        )
        x += item.size.width + spacing
      }

      y += row.height + spacing
    }
  }

  private func rows(in width: CGFloat, subviews: Subviews) -> [Row] {
    var rows: [Row] = []
    var currentRow = Row()

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      let nextWidth = currentRow.items.isEmpty
        ? size.width
        : currentRow.width + spacing + size.width

      if nextWidth > width, !currentRow.items.isEmpty {
        rows.append(currentRow)
        currentRow = Row()
      }

      currentRow.items.append(RowItem(subview: subview, size: size))
      currentRow.width = currentRow.items.isEmpty ? 0 : min(max(currentRow.width, nextWidth), width)
      currentRow.height = max(currentRow.height, size.height)
    }

    if !currentRow.items.isEmpty {
      rows.append(currentRow)
    }

    return rows
  }

  private struct Row {
    var items: [RowItem] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
  }

  private struct RowItem {
    let subview: LayoutSubview
    let size: CGSize
  }
}

#Preview {
  VoiceNoteTagsSection(
    tags: ["running", "marathon", "city park"],
    title: "Tags"
  )
}
