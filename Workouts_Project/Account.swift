//
//  Account.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 13/06/25.
//


import SwiftData

@Model
final class Account {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    @Relationship var goalSetting: GoalSetting?

    init(id: UUID = UUID(), name: String, email: String, goalSetting: GoalSetting? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.goalSetting = goalSetting
    }
}

@Model
final class GoalSetting {
    @Attribute(.unique) var id: UUID
    var dailyCalorieGoal: Int
    var weeklyExerciseMinutes: Int

    init(id: UUID = UUID(), dailyCalorieGoal: Int, weeklyExerciseMinutes: Int) {
        self.id = id
        self.dailyCalorieGoal = dailyCalorieGoal
        self.weeklyExerciseMinutes = weeklyExerciseMinutes
    }
}


import SwiftUI
import SwiftData

struct AccountListView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]

    @State private var name = ""
    @State private var email = ""
    @State private var calorieGoal = ""
    @State private var exerciseMinutes = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Form {
                    Section(header: Text("New Account")) {
                        TextField("Name", text: $name)
                        TextField("Email", text: $email)
                        TextField("Daily Calorie Goal", text: $calorieGoal)
                            .keyboardType(.numberPad)
                        TextField("Weekly Exercise Minutes", text: $exerciseMinutes)
                            .keyboardType(.numberPad)
                        Button("Create Account") {
                            createAccount()
                        }
                    }
                }

                List {
                    ForEach(accounts) { account in
                        VStack(alignment: .leading) {
                            Text(account.name).font(.headline)
                            Text(account.email).foregroundColor(.gray)
                            if let goal = account.goalSetting {
                                Text("Calories: \(goal.dailyCalorieGoal), Exercise: \(goal.weeklyExerciseMinutes) mins")
                                    .font(.subheadline)
                            }
                            Button("Update Goal") {
                                updateGoal(for: account)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .onDelete(perform: deleteAccounts)
                }
            }
            .navigationTitle("Accounts")
        }
    }

    private func createAccount() {
        guard let cal = Int(calorieGoal), let mins = Int(exerciseMinutes) else { return }

        let goal = GoalSetting(dailyCalorieGoal: cal, weeklyExerciseMinutes: mins)
        let newAccount = Account(name: name, email: email, goalSetting: goal)

        context.insert(newAccount)
        try? context.save()
        
        name = ""
        email = ""
        calorieGoal = ""
        exerciseMinutes = ""
    }

    private func updateGoal(for account: Account) {
        if let goal = account.goalSetting {
            goal.dailyCalorieGoal += 100
            goal.weeklyExerciseMinutes += 10
        } else {
            account.goalSetting = GoalSetting(dailyCalorieGoal: 2000, weeklyExerciseMinutes: 150)
        }
        try? context.save()
    }

    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            context.delete(accounts[index])
        }
        try? context.save()
    }
}


#Preview(body: {
    AccountListView()
})
