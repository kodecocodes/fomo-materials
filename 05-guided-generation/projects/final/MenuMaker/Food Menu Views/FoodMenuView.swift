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
  @State private var showTranscript = false
  @State private var cuisineList: [String]?
  @State private var cuisine = "N/A"
  @State private var ingredientList = [String]()
  @State private var selectedIngredients = [String]()
  @State private var mealtimes = ["Breakfast", "Lunch", "Dinner", "Dessert"]
  @State private var selectedMeal: String = "Lunch"
  @State private var showControls = true
  @State private var isGenerating = false
  @State private var menu: RestaurantMenu.PartiallyGenerated?
  @State private var specialIngredients = [String]()
  @State var special: MenuItem?
  
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
              Divider()
              Text("Special Ingredients")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
              if !ingredientList.isEmpty {
                MultiSelectView(
                  options: $ingredientList,
                  selections: $specialIngredients,
                  maxSelect: 3
                )
              } else {
                Text("Select a cuisine first.")
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }
              Button("Generate \(selectedMeal) Menu") {
                withAnimation {
                  showControls = false
                }
                Task {
                  await generateLunchMenu()
                  await generateMenuSpecial()
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
            .task {
              generateCuisineList()
            }
            .onChange(of: cuisine) { _ , _ in
              Task {
                ingredientList = []
                selectedIngredients = []
                await ingredientList = generateIngredients()
              }
            }
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
        if let special = special {
          VStack {
            Text("Today's Special")
              .font(.title2)
            MenuItemView(
              menuItem: special.asPartiallyGenerated()
            )
          }
          .featuredCard()
          .padding(.bottom, 8)
        }
        if let menu = menu {
          if let type = menu.type {
            Text("\(type.rawValue.capitalized) Menu")
              .font(.headline.bold())
          }
          if let menuitems = menu.menu {
            ScrollView {
              ForEach(menuitems, id: \.name) { item in
                MenuItemView(menuItem: item)
                Divider()
              }
            }
          }
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
  
  func generateIngredients() async -> [String] {
    // 1
    guard cuisine != "N/A" else { return [] }
    isGenerating = true
    defer { isGenerating = false }
    
    // 2
    let ingredientPrompt = """
      Give me a list of ingredients used in \(cuisine) for \(selectedMeal).
      """
    let session = LanguageModelSession()
    
    // 3
    let response = try? await session.respond(to: ingredientPrompt, generating: CuisineIngredients.self)
    
    // 4
    if let response = response {
      return response.content.ingredients
    } else {
      return []
    }
  }
  
  // 1
  func generateLunchMenu() async {
    isGenerating = true
    defer {
      isGenerating = false
    }

    // 2
    let instructions = """
      You are generating a simple, plausible restaurant menu for a restaurant in a game.
      The menu must match the given cuisine and meal type.
      Use at least ONE ingredient from the provided ingredient list but you may include additional ingredients beyond the provided list.
      Avoid repeating the same primary ingredient across all dishes.
    """
    let session = LanguageModelSession(instructions: instructions)

    // 3
    let prompt = """
      Create a menu for \(selectedMeal) at a \(cuisine)) restaurant.
      Each meal on the menu must include one of the following ingredients: \(selectedIngredients.joined(separator: ", "))

      Requirements:
      - Each dish must include at least ONE of the available ingredients.
      - Dishes should be appropriate for the cuisine and meal type.
      - Keep items simple, recognizable, and realistic (not overly complex or experimental).
      - Vary the primary ingredients across dishes when possible.
      - Prices should feel reasonable for a casual restaurant in USD.
      """
    // 4
    let streamedResponse = session.streamResponse(to: prompt, generating: RestaurantMenu.self)
    // 5
    do {
      for try await partialResponse in streamedResponse {
        menu = partialResponse.content
      }
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func generateMenuSpecial() async {
    // 1
    let specialMealSchema = DynamicGenerationSchema(
      name: "specialmenuitem",
      // 2
      properties: [
        // 3
        DynamicGenerationSchema.Property(
          name: "ingredients",
          // 4
          schema: DynamicGenerationSchema(
            name: "ingredients",
            anyOf: specialIngredients
          )
        ),
        // 5
        DynamicGenerationSchema.Property(
          name: "name",
          schema: DynamicGenerationSchema(type: String.self)
        ),
        DynamicGenerationSchema.Property(
          name: "description",
          schema: DynamicGenerationSchema(type: String.self)
        ),
        DynamicGenerationSchema.Property(
          name: "price",
          schema: DynamicGenerationSchema(type: Decimal.self)
        )
      ]
    )
    
    // 1
    let schema = try? GenerationSchema(root: specialMealSchema, dependencies: [])
    // 2
    guard let schema = schema else { return }
    // 3
    let session = LanguageModelSession(instructions: "You are a helpful model assisting with generating realistic restaurant menus.")
    let specialPrompt = "Produce a lunch special menu item that is focused on the specified ingredient."
    let response = try? await session.respond(to: specialPrompt, schema: schema)
    
    let name = try? response?.content.value(String.self, forProperty: "name")
    let ingredients = try? response?.content.value(String.self, forProperty: "ingredients")
    let description = try? response?.content.value(String.self, forProperty: "description")
    let price = try? response?.content.value(Decimal.self, forProperty: "price")
    let specialItem = MenuItem(
      name: name ?? "",
      description: description ?? "",
      ingredients: ingredients == nil ? [] : [ingredients!],
      cost: price ?? 0.0
    )

    special = specialItem
  }
}

#Preview {
  FoodMenuView()
}
