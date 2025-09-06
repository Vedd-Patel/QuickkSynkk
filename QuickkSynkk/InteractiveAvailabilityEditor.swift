//
//  InteractiveAvailabilityEditor.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//


import SwiftUI

struct InteractiveAvailabilityEditor: View {
    @Binding var availability: [AvailabilitySlot]
    
    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let hours = Array(9...17) // 9AM to 5PM
    
    var body: some View {
        VStack(spacing: 12) {
            // Instructions
            Text("Tap to toggle your availability")
                .font(.system(size: 14))
                .foregroundColor(.appSecondary)
                .padding(.bottom, 8)
            
            // Header with hours
            HStack {
                Text("Day")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.appText)
                    .frame(width: 40, alignment: .leading)
                
                ForEach([9, 12, 15], id: \.self) { hour in
                    Text(formatHour(hour))
                        .font(.system(size: 9))
                        .foregroundColor(.appSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Interactive grid
            ForEach(0..<7, id: \.self) { dayIndex in
                HStack(spacing: 2) {
                    Text(days[dayIndex])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.appText)
                        .frame(width: 40, alignment: .leading)
                    
                    ForEach(hours, id: \.self) { hour in
                        Button(action: {
                            toggleAvailability(day: dayIndex, hour: hour)
                        }) {
                            Rectangle()
                                .fill(isTimeSlotAvailable(day: dayIndex, hour: hour) ? 
                                      Color.filterGreen : Color.buttonUnselected)
                                .frame(height: 20)
                                .cornerRadius(3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.appSecondary, lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Quick actions
            HStack(spacing: 16) {
                Button("Clear All") {
                    clearAllAvailability()
                }
                .quickActionButton(color: .filterRed)
                
                Button("Weekdays") {
                    setWeekdaysOnly()
                }
                .quickActionButton(color: .filterBlue)
                
                Button("Select All") {
                    selectAllAvailability()
                }
                .quickActionButton(color: .filterGreen)
            }
            .padding(.top, 12)
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.filterGreen)
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                    Text("Available")
                        .font(.system(size: 11))
                        .foregroundColor(.appText)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.buttonUnselected)
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                    Text("Not Available")
                        .font(.system(size: 11))
                        .foregroundColor(.appText)
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .onAppear {
            initializeAvailabilityIfNeeded()
        }
    }
    
    func isTimeSlotAvailable(day: Int, hour: Int) -> Bool {
        return availability.contains { slot in
            slot.dayOfWeek == day && hour >= slot.startHour && hour < slot.endHour && slot.isAvailable
        }
    }
    
    func toggleAvailability(day: Int, hour: Int) {
        // Remove any existing slot for this time
        availability.removeAll { slot in
            slot.dayOfWeek == day && hour >= slot.startHour && hour < slot.endHour
        }
        
        // Add new slot or toggle existing
        if !isTimeSlotAvailable(day: day, hour: hour) {
            let newSlot = AvailabilitySlot(
                dayOfWeek: day,
                startHour: hour,
                endHour: hour + 1,
                isAvailable: true
            )
            availability.append(newSlot)
        }
        
        // Merge consecutive slots
        mergeConsecutiveSlots()
    }
    
    func mergeConsecutiveSlots() {
        var mergedSlots: [AvailabilitySlot] = []
        let sortedSlots = availability.sorted { 
            $0.dayOfWeek < $1.dayOfWeek || ($0.dayOfWeek == $1.dayOfWeek && $0.startHour < $1.startHour)
        }
        
        for slot in sortedSlots {
            if let lastSlot = mergedSlots.last,
               lastSlot.dayOfWeek == slot.dayOfWeek,
               lastSlot.endHour == slot.startHour,
               lastSlot.isAvailable == slot.isAvailable {
                // Merge with previous slot
                mergedSlots[mergedSlots.count - 1] = AvailabilitySlot(
                    dayOfWeek: lastSlot.dayOfWeek,
                    startHour: lastSlot.startHour,
                    endHour: slot.endHour,
                    isAvailable: lastSlot.isAvailable
                )
            } else {
                mergedSlots.append(slot)
            }
        }
        
        availability = mergedSlots
    }
    
    func clearAllAvailability() {
        availability.removeAll()
    }
    
    func selectAllAvailability() {
        // Create availability for all time slots
        var allSlots: [AvailabilitySlot] = []
        for day in 0...6 {
            let slot = AvailabilitySlot(
                dayOfWeek: day,
                startHour: 9,
                endHour: 18,
                isAvailable: true
            )
            allSlots.append(slot)
        }
        availability = allSlots
    }
    
    func setWeekdaysOnly() {
        availability.removeAll()
        
        // Set weekdays (Monday-Friday) available
        for day in 1...5 { // Monday = 1, Friday = 5
            let slot = AvailabilitySlot(
                dayOfWeek: day,
                startHour: 9,
                endHour: 17,
                isAvailable: true
            )
            availability.append(slot)
        }
    }
    
    func initializeAvailabilityIfNeeded() {
        if availability.isEmpty {
            // Start with weekdays as default
            setWeekdaysOnly()
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

// MARK: - Supporting Views

struct EmptyAvailabilityView: View {
    let onSetAvailability: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(.appSecondary)
            
            Text("No availability set")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.appText)
            
            Text("Set your availability to help teammates find the best time to collaborate")
                .font(.system(size: 14))
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
            
            Button("Set Availability") {
                onSetAvailability()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.filterBlue)
            .cornerRadius(20)
        }
        .padding(20)
        .frame(height: 200)
    }
}

extension View {
    func quickActionButton(color: Color) -> some View {
        self
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(12)
    }
}

#Preview {
    InteractiveAvailabilityEditor(availability: .constant([
        AvailabilitySlot(dayOfWeek: 1, startHour: 9, endHour: 17, isAvailable: true),
        AvailabilitySlot(dayOfWeek: 2, startHour: 9, endHour: 17, isAvailable: true)
    ]))
    .padding()
}
