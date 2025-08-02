//
//  Theme.swift
//  NutritionTracker
//
//  Visual design system with colors, spacing, and styling
//

import SwiftUI
import UIKit

struct AppTheme {
    // MARK: - Colors
    static let primaryGreen = Color(red: 0.2, green: 0.7, blue: 0.4)
    static let secondaryGreen = Color(red: 0.15, green: 0.55, blue: 0.3)
    
    // Dark mode adaptive backgrounds using Color.init with light/dark variants
    static let lightGreen = Color(.systemGreen).opacity(0.1)
    static let darkGreen = Color(.systemGreen).opacity(0.2)
    
    static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let lightOrange = Color(.systemOrange).opacity(0.1)
    static let darkOrange = Color(.systemOrange).opacity(0.2)
    
    // Adaptive color getters
    static func adaptiveLightGreen(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkGreen : lightGreen
    }
    
    static func adaptiveLightOrange(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkOrange : lightOrange
    }
    
    static let cardBackground = Color(UIColor.systemBackground)
    static let cardShadow = Color.black.opacity(0.05)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)
    
    // MARK: - Typography
    static let titleFont = Font.system(size: 24, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 14, weight: .medium, design: .default)
    static let smallFont = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Spacing
    static let paddingXS: CGFloat = 4
    static let paddingS: CGFloat = 8
    static let paddingM: CGFloat = 16
    static let paddingL: CGFloat = 24
    static let paddingXL: CGFloat = 32
    
    // MARK: - Corner Radius
    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
    static let radiusL: CGFloat = 16
    
    // MARK: - Shadow
    static let shadowRadius: CGFloat = 6
    static let shadowOffset = CGSize(width: 0, height: 2)
}

// MARK: - Card Style
struct CardStyle: ViewModifier {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let showShadow: Bool
    
    init(
        backgroundColor: Color = AppTheme.cardBackground,
        cornerRadius: CGFloat = AppTheme.radiusM,
        showShadow: Bool = true
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
    }
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: showShadow ? AppTheme.cardShadow : Color.clear,
                radius: showShadow ? AppTheme.shadowRadius : 0,
                x: AppTheme.shadowOffset.width,
                y: AppTheme.shadowOffset.height
            )
    }
}

extension View {
    func cardStyle(
        backgroundColor: Color = AppTheme.cardBackground,
        cornerRadius: CGFloat = AppTheme.radiusM,
        showShadow: Bool = true
    ) -> some View {
        self.modifier(CardStyle(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            showShadow: showShadow
        ))
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headlineFont)
            .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
            .padding(.horizontal, AppTheme.paddingL)
            .padding(.vertical, AppTheme.paddingM)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusM)
                    .fill(AppTheme.primaryGreen)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.bodyFont)
            .foregroundColor(AppTheme.primaryGreen)
            .padding(.horizontal, AppTheme.paddingM)
            .padding(.vertical, AppTheme.paddingS)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusS)
                    .fill(AppTheme.adaptiveLightGreen(colorScheme))
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}