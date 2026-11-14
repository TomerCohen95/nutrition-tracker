import SwiftUI

struct PersonalFoodSettings: View {
    @AppStorage(PersonalFood.storageKey) private var data = Data()
    @State private var editing: PersonalFood?

    private var foods: [PersonalFood] { PersonalFood.read(data) }

    var body: some View {
        List {
            Section {
                if foods.isEmpty {
                    Text("אין עדיין מאכלים שמורים")
                        .foregroundStyle(.secondary)
                }
                ForEach(foods) { food in
                    Button {
                        editing = food
                    } label: {
                        VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                            Text(food.name)
                                .foregroundStyle(.primary)
                            if let grams = food.defaultGrams {
                                Text("\(food.calories) קלוריות ל־100 גרם, ברירת מחדל \(grams) גרם")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(food.calories) קלוריות למנה")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            if let protein = food.protein {
                                Text("\(protein) גרם חלבון \(food.defaultGrams == nil ? "למנה" : "ל־100 גרם")")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    var updated = foods
                    updated.remove(atOffsets: offsets)
                    persist(updated)
                }
            } footer: {
                Text("ברישום קולי, הערכים שכאן קודמים להיסטוריית היומן ולמאגר החיצוני.")
            }
        }
        .navigationTitle("המאכלים שלי")
        .toolbar {
            Button("הוספת מאכל", systemImage: "plus") {
                editing = PersonalFood(name: "", calories: 0)
            }
            .labelStyle(.iconOnly)
            .disabled(foods.count >= 100)
        }
        .sheet(item: $editing) { food in
            PersonalFoodEditor(food: food) { updated in
                var entries = foods
                if let index = entries.firstIndex(where: { $0.id == updated.id }) {
                    entries[index] = updated
                } else {
                    entries.append(updated)
                }
                persist(entries)
            }
        }
    }

    private func persist(_ foods: [PersonalFood]) {
        if let encoded = try? JSONEncoder().encode(foods) {
            data = encoded
        }
    }
}

private struct PersonalFoodEditor: View {
    @Environment(\.dismiss) private var dismiss
    let food: PersonalFood
    let onSave: (PersonalFood) -> Void

    @State private var name: String
    @State private var calories: String
    @State private var protein: String
    @State private var perWeight: Bool
    @State private var grams: String

    init(food: PersonalFood, onSave: @escaping (PersonalFood) -> Void) {
        self.food = food
        self.onSave = onSave
        _name = State(initialValue: food.name)
        _calories = State(initialValue: food.name.isEmpty ? "" : String(food.calories))
        _protein = State(initialValue: food.protein.map { String($0) } ?? "")
        _perWeight = State(initialValue: food.defaultGrams != nil)
        _grams = State(initialValue: food.defaultGrams.map { String($0) } ?? "100")
    }

    private var updated: PersonalFood? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 120,
              let kcal = Int(calories), (0...10_000).contains(kcal)
        else { return nil }

        let proteinValue = Int(protein)
        guard protein.isEmpty || proteinValue.map({ (0...1_000).contains($0) }) == true else { return nil }

        let weight = Int(grams)
        guard !perWeight || weight.map({ (1...10_000).contains($0) }) == true else { return nil }

        return PersonalFood(id: food.id, name: trimmed, calories: kcal, protein: proteinValue,
                            defaultGrams: perWeight ? weight : nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("שם המאכל", text: $name)
                Picker("יחידה", selection: $perWeight) {
                    Text("למנה").tag(false)
                    Text("ל־100 גרם").tag(true)
                }
                TextField("קלוריות", text: $calories).keyboardType(.numberPad)
                TextField("חלבון בגרמים (אופציונלי)", text: $protein).keyboardType(.numberPad)
                if perWeight {
                    TextField("משקל ברירת מחדל בגרמים", text: $grams).keyboardType(.numberPad)
                }
            }
            .navigationTitle("פרטי מאכל")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמירה") {
                        guard let updated else { return }
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(updated == nil)
                }
            }
        }
    }
}
