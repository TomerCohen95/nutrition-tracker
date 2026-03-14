//
//  FoodItemCard.swift
//  NutritionTracker
//
//  Reusable food item card component
//

import SwiftUI
import SwiftData

struct FoodItemCard: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    let item: FoodItem
    let onToggle: () -> Void
    let onUpdate: (() -> Void)?
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(item: FoodItem, onToggle: @escaping () -> Void, onUpdate: (() -> Void)? = nil, onEdit: @escaping () -> Void, onCopy: @escaping () -> Void, onDuplicate: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.item = item
        self.onToggle = onToggle
        self.onUpdate = onUpdate
        self.onEdit = onEdit
        self.onCopy = onCopy
        self.onDuplicate = onDuplicate
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: AppTheme.paddingM) {
            // Status Toggle Button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(item.status == .eaten ? AppTheme.primaryGreen : AppTheme.cardBackground)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(item.status == .eaten ? AppTheme.primaryGreen : AppTheme.textTertiary, lineWidth: 2)
                        )
                    
                    if item.status == .eaten {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Food Info
            VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                Text(item.name)
                    .font(AppTheme.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack(spacing: AppTheme.paddingXS) {
                    Image(systemName: item.status == .eaten ? "checkmark.circle.fill" : "clock")
                        .font(.system(size: 12))
                        .foregroundColor(item.status == .eaten ? AppTheme.primaryGreen : AppTheme.textTertiary)
                    
                    Text(item.status.displayName)
                        .font(AppTheme.smallFont)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Calories Badge
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.calories)")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("kcal • \(item.proteinGrams)g")
                    .font(AppTheme.smallFont)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, AppTheme.paddingS)
            .padding(.vertical, AppTheme.paddingXS)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusS)
                    .fill(item.status == .eaten ? AppTheme.adaptiveLightGreen(colorScheme) : AppTheme.adaptiveLightOrange(colorScheme))
            )
            
        }
        .padding(AppTheme.paddingM)
        .cardStyle()
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Button {
                onCopy()
            } label: {
                Label("Copy to Days", systemImage: "calendar.badge.plus")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    let item = FoodItem(name: "Apple", calories: 95, proteinGrams: 0)
    return FoodItemCard(
        item: item,
        onToggle: { },
        onEdit: { },
        onCopy: { },
        onDuplicate: { },
        onDelete: { }
    )
    .modelContainer(for: FoodItem.self, inMemory: true)
}
