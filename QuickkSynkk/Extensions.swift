//
//  Extensions.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//

import SwiftUI

// MARK: - App Colors (Solid Colors Only)
extension Color {
    // Primary Colors
    static let appBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let appAccent = Color(red: 0.9, green: 0.93, blue: 0.8)
    static let appText = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let appSecondary = Color(red: 0.6, green: 0.6, blue: 0.6)
    
    // Additional Solid Colors
    static let cardBackground = Color.white
    static let buttonSelected = Color(red: 0.9, green: 0.93, blue: 0.8)
    static let buttonUnselected = Color(red: 0.9, green: 0.9, blue: 0.9)
    static let textOnButton = Color.black
    static let textOnUnselected = Color(red: 0.3, green: 0.3, blue: 0.3)
    
    // Filter Colors
    static let filterGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let filterBlue = Color(red: 0.2, green: 0.6, blue: 0.9)
    static let filterOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let filterPurple = Color(red: 0.6, green: 0.4, blue: 0.9)
    static let filterRed = Color(red: 0.9, green: 0.3, blue: 0.3)
    
    // Background Colors
    static let backgroundDark = Color(red: 0.15, green: 0.2, blue: 0.3)
    static let backgroundMedium = Color(red: 0.25, green: 0.3, blue: 0.4)
    static let backgroundLight = Color(red: 0.9, green: 0.9, blue: 0.95)
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func glassBackground() -> some View {
        self
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.appSecondary, lineWidth: 1)
            )
    }
    
    func pillButton(selected: Bool = false) -> some View {
        self
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(selected ? Color.buttonSelected : Color.buttonUnselected)
            )
            .foregroundColor(selected ? .textOnButton : .textOnUnselected)
            .overlay(
                Capsule()
                    .stroke(selected ? Color.appAccent : Color.appSecondary, lineWidth: 2)
            )
    }
    
    func primaryButton() -> some View {
        self
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.textOnButton)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(Color.buttonSelected)
            )
            .overlay(
                Capsule()
                    .stroke(Color.appAccent, lineWidth: 2)
            )
    }
    
    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appSecondary, lineWidth: 1)
            )
            .shadow(color: Color.gray, radius: 4, x: 0, y: 2)
    }
}
