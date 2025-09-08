//
//  NavigationStackLearning.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 01/09/25.
//

import SwiftUI

struct NavigationStackLearning: View {
    @State private var path = [Int]()

    var body: some View {
        NavigationStack(path: $path) {
            List(1..<6) { item in
                NavigationLink(value: item) {
                    Text("Item \(item)")
                }
            }
            .navigationDestination(for: Int.self) { value in
                VStack {
                    Text("Detail for \(value)")
                    Button("Go deeper") {
                        path.append(value + 1)
                    }
                }
            }
        }
    }
}

#Preview {
    SplitViewExample()
}

import SwiftUI

// MARK: - Models
struct Category: Identifiable, Hashable {
    let id: UUID
    let name: String
    let recipes: [Recipe]
}

struct Recipe: Identifiable, Hashable {
    let id: UUID
    let name: String
    let ingredients: [Ingredient]
}

struct Ingredient: Identifiable, Hashable {
    let id: UUID
    let name: String
    let quantity: String
}

// MARK: - Route (optional but nice)
enum Route: Hashable {
    case category(Category)
    case recipe(Recipe)
    case ingredient(Ingredient)
}

struct RecipesListView: View {
    @State private var path: [Route] = []

    // Fake data
    private let categories: [Category] = {
        let salt = Ingredient(id: .init(), name: "Salt", quantity: "1 tsp")
        let egg  = Ingredient(id: .init(), name: "Egg",  quantity: "2 pcs")
        let r1 = Recipe(id: .init(), name: "Scrambled Eggs", ingredients: [egg, salt])
        let r2 = Recipe(id: .init(), name: "Omelette",       ingredients: [egg, salt])
        return [
            Category(id: .init(), name: "Breakfast", recipes: [r1, r2]),
            Category(id: .init(), name: "Lunch",     recipes: [r2])
        ]
    }()

    var body: some View {
        NavigationStack(path: $path) {
            // LEVEL 1: Categories
            List(categories) { category in
                NavigationLink(value: Route.category(category)) {
                    Text(category.name)
                }
            }
            .navigationTitle("Categories")
            // Destinations for all route types
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .category(let category):
                    CategoryView(category: category) { recipe in
                        path.append(.recipe(recipe))            // programmatic push
                    }

                case .recipe(let recipe):
                    RecipeView(recipe: recipe,
                               onIngredientTap: { ing in path.append(.ingredient(ing)) },
                               onBackToCategories: { path.removeAll() }) // pop to root

                case .ingredient(let ingredient):
                    IngredientView(ingredient: ingredient,
                                   replaceWithVariant: { variant in
                                       // replace last (ingredient) with another ingredient
                                       _ = path.popLast()
                                       path.append(.ingredient(variant))
                                   })
                }
            }
        }
    }
}

// MARK: - Screens

struct CategoryView: View {
    let category: Category
    var onRecipeTap: (Recipe) -> Void

    var body: some View {
        List(category.recipes) { recipe in
            Button {
                onRecipeTap(recipe)
            } label: {
                HStack {
                    Text(recipe.name)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(category.name)
    }
}

struct RecipeView: View {
    let recipe: Recipe
    var onIngredientTap: (Ingredient) -> Void
    var onBackToCategories: () -> Void

    var body: some View {
        VStack {
            List(recipe.ingredients) { ing in

                
                Button { onIngredientTap(ing) } label: {
                    HStack {
                        Text(ing.name)
                        Spacer()
                        Text(ing.quantity).foregroundStyle(.secondary)
                    }
                }
            }

            // Example controls for stack operations
            HStack {
                Button("Pop 1 level") {
                    // handled automatically by back button, but you can also control via environment later
                }
                Spacer()
                Button("Back to Categories") { onBackToCategories() } // path.removeAll()
            }
            .padding(.horizontal)
        }
        .navigationTitle(recipe.name)
    }
}

struct IngredientView: View {
    let ingredient: Ingredient
    var replaceWithVariant: (Ingredient) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(ingredient.name).font(.title2)
            Text("Qty: \(ingredient.quantity)").foregroundStyle(.secondary)

            Button("Swap with coarse salt") {
                let variant = Ingredient(id: .init(), name: "Coarse Salt", quantity: ingredient.quantity)
                replaceWithVariant(variant) // path replace
            }
        }
        .padding()
        .navigationTitle("Ingredient")
    }
}

import SwiftUI

struct SplitViewExample: View {
    @State private var selectedItem: String? = "Item 1"

    var body: some View {
        NavigationSplitView {
            List(["Item 1", "Item 2", "Item 3"], id: \.self, selection: $selectedItem) { item in
                Text(item)
            }
            .navigationTitle("Sidebar")
        } content: {
            if let item = selectedItem {
                Text("Selected: \(item)")
                    .navigationTitle("Sidebar2")
            } else {
                Text("Choose an item")
            }
        } detail: {
            Text("Detail view (optional third column)")
                .navigationTitle("Sidebar3")
        }
    }
}
