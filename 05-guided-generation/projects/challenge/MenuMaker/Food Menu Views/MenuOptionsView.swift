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

struct MenuOptionsView: View {
  var mealtimes: [String]
  @Binding var selectedMeal: String
  var cuisineList: [String]?
  @Binding var cuisine: String
  var ingredientList: [String]
  @Binding var selectedIngredients: [String]
  @Binding var specialIngredients: [String]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        HStack {
          Text("Meal")
          Picker("Meal", selection: $selectedMeal) {
            ForEach(mealtimes, id: \.self) {
              Text($0).tag($0)
            }
          }
          .pickerStyle(.segmented)
        }
        HStack {
          Text("Cuisine Type")
          if let cuisineList = cuisineList {
            Picker("Cuisine", selection: $cuisine) {
              Text("--Select Cuisine--").tag("N/A")
              ForEach(cuisineList, id: \.self) {
                Text($0).tag($0)
              }
            }
            .frame(maxWidth: .infinity)
          }
        }
        Text("Ingredients")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .textCase(.uppercase)
        if !ingredientList.isEmpty {
          MultiSelectView(
            options: ingredientList,
            selections: $selectedIngredients
          )
        } else {
          Text("Select a cuisine first.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Divider()
        Text("Special Ingredients")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .textCase(.uppercase)
        if !ingredientList.isEmpty {
          MultiSelectView(
            options: ingredientList,
            selections: $specialIngredients,
            maxSelect: 3
          )
        } else {
          Text("Select a cuisine first.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
      .padding()
      .background(
        .gray.mix(with: .white, by: 0.8),
        in: RoundedRectangle(
          cornerRadius: 20,
          style: .continuous
        )
      )
      .transition(
        .move(edge: .top)
        .combined(with: .opacity)
      )
    }
  }
}

#Preview {
  @Previewable @State var selectedMeal = "Lunch"
  @Previewable @State var cuisine = "N/A"
  @Previewable @State var selectedIngredients: [String] = []
  @Previewable @State var specialIngredients: [String] = []
  let mealtimes = ["Breakfast", "Lunch", "Dinner", "Dessert"]
  let cuisineList = [
    "American", "Italian", "French", "Asian", "Mediterranean",
    "Indian", "Caribbean",
  ]
  let ingredientList = ["onion", "salmon", "chicken", "olives", "tomatoes", "garlic", "beef"]
  
  MenuOptionsView(
    mealtimes: mealtimes,
    selectedMeal: $selectedMeal,
    cuisineList: cuisineList,
    cuisine: $cuisine,
    ingredientList: ingredientList,
    selectedIngredients: $selectedIngredients,
    specialIngredients: $specialIngredients
  )
}
