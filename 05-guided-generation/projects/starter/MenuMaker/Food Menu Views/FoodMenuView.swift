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

struct FoodMenuView: View {
  @State var menu: RestaurantMenu.PartiallyGenerated?
  @State var special: MenuItem?
  @State private var showTranscript = false
  @State private var cuisineList: [String]?
  @State private var cuisine = "N/A"
  @State private var ingredientList = [String]()
  @State private var selectedIngredients = [String]()
  @State private var mealtimes = ["Breakfast", "Lunch", "Dinner", "Desserts"]
  @State private var selectedMeal: String = "Lunch"
  @State private var showControls = true
  @State private var isGenerating = false
  
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 0) {
        Group {
          Button {
            withAnimation(.easeInOut) {
              showControls.toggle()
            }
          } label: {
            Label(
              showControls ? "Hide Options" : "Show Options",
              systemImage: showControls ? "chevron.up" : "chevron.down"
            )
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .trailing)
          }
          .buttonStyle(.plain)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          
          if showControls {
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
                  options: $ingredientList,
                  selections: $selectedIngredients
                )
              } else {
                Text("Select a cuisine first.")
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }
              Button("Generate \(selectedMeal) Menu") {
                Task {
                  withAnimation {
                    showControls = false
                  }
                  isGenerating = true
                }
              }
              .frame(maxWidth: .infinity)
              .buttonStyle(.borderedProminent)
              .disabled(
                selectedIngredients.isEmpty || cuisine == "N/A"
              )
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

        if isGenerating {
          Label("Generating Menu", systemImage: "sparkles")
            .font(.title3)
            .foregroundStyle(.secondary)
            .symbolEffect(
              .pulse,
              isActive: isGenerating
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
        }
        Spacer()
      }
      .navigationTitle("Menu Maker")
      .navigationBarTitleDisplayMode(.inline)
    }
    .padding()
  }

  func generateCuisineList() {
    cuisineList = [
      "American", "Italian", "French", "Asian", "Mediterranean",
      "Indian", "Caribbean",
    ]
  }
}

#Preview {
  FoodMenuView()
}
