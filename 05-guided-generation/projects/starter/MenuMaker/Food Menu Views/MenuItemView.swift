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

struct MenuItemView: View {
  var menuItem: MenuItem
  
  var body: some View {
    VStack {
      HStack {
        Text(menuItem.name)
          .font(.headline.bold())
        Spacer()
        Text(menuItem.cost, format: .currency(code: "USD"))
          .font(.headline)
      }
      .font(.title3)
      Text(menuItem.description)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 15.0)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text(menuItem.ingredients.joined(separator: " • "))
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .padding(.vertical, 10)
  }
}

#Preview {
  let item = MenuItem(
    name: "Caesar Salad",
    description: "Romaine lettuce tossed in Caesar dressing with parmesan cheese and croutons.",
    ingredients: ["romaine lettuce", "Caesar dressing", "parmesan cheese", "croutons"],
    cost: 10.0
  )
  MenuItemView(
    menuItem: item
  )
}
