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

struct FlowLayout: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
    let rows = makeRows(proposal: proposal, subviews: subviews)
    let height = rows.reduce(0) { total, row in
      total + (row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0)
    } + CGFloat(max(rows.count - 1, 0)) * spacing
    return CGSize(width: proposal.width ?? 0, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
    let rows = makeRows(proposal: proposal, subviews: subviews)
    var y = bounds.minY
    for row in rows {
      var x = bounds.minX
      let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
      for subview in row {
        let size = subview.sizeThatFits(.unspecified)
        subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
        x += size.width + spacing
      }
      y += rowHeight + spacing
    }
  }

  private func makeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
    let maxWidth = proposal.width ?? .infinity
    var rows: [[LayoutSubview]] = [[]]
    var rowWidth: CGFloat = 0
    for subview in subviews {
      let width = subview.sizeThatFits(.unspecified).width
      if rowWidth + width > maxWidth, !rows[rows.count - 1].isEmpty {
        rows.append([])
        rowWidth = 0
      }
      rows[rows.count - 1].append(subview)
      rowWidth += width + spacing
    }
    return rows
  }
}
