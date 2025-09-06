//
//  AvailabilityHeatmapView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//


import SwiftUI

struct AvailabilityHeatmapView: View {
    let availability: [AvailabilitySlot]
    
    private let days = ["S", "M", "T", "W", "T", "F", "S"]
    private let hours = Array(9...17) // Work hours
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Time")
                    .font(.system(size: 10))
                    .foregroundColor(.appSecondary)
                    .frame(width: 30)
                
                ForEach([9, 12, 15], id: \.self) { hour in
                    Text(formatHour(hour))
                        .font(.system(size: 10))
                        .foregroundColor(.appSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Heatmap
            ForEach(0..<7, id: \.self) { dayIndex in
                HStack(spacing: 4) {
                    Text(days[dayIndex])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appText)
                        .frame(width: 30)
                    
                    ForEach(hours, id: \.self) { hour in
                        Rectangle()
                            .fill(isAvailable(day: dayIndex, hour: hour) ? Color.appAccent : Color.appSecondary.opacity(0.3))
                            .frame(height: 16)
                            .cornerRadius(2)
                    }
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.appAccent)
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                    Text("Available")
                        .font(.system(size: 12))
                        .foregroundColor(.appText)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.appSecondary.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                    Text("Unavailable")
                        .font(.system(size: 12))
                        .foregroundColor(.appText)
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
    }
    
    func isAvailable(day: Int, hour: Int) -> Bool {
        return availability.contains { slot in
            slot.dayOfWeek == day && hour >= slot.startHour && hour < slot.endHour && slot.isAvailable
        }
    }
    
    func formatHour(_ hour: Int) -> String {
        if hour == 12 {
            return "12PM"
        } else if hour > 12 {
            return "\(hour - 12)PM"
        } else {
            return "\(hour)AM"
        }
    }
}

#Preview {
    AvailabilityHeatmapView(availability: [
        AvailabilitySlot(dayOfWeek: 1, startHour: 9, endHour: 17, isAvailable: true),
        AvailabilitySlot(dayOfWeek: 2, startHour: 9, endHour: 17, isAvailable: true),
        AvailabilitySlot(dayOfWeek: 3, startHour: 9, endHour: 17, isAvailable: true)
    ])
    .padding()
}
