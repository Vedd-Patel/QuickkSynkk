//
//  ProfileView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//


import SwiftUI

struct ProfileView: View {
    @State private var isEditingAvailability = false
    @State private var editedAvailability: [AvailabilitySlot] = []
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showingSignOutAlert = false
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedBio = ""
    @State private var editedSkills: [String] = []
    @State private var editedInterests: [String] = []
    @State private var newSkill = ""
    @State private var newInterest = ""
    
    var currentUser: User {
        firebaseManager.currentUser ?? User(name: "", email: "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileHeaderSection
                        statsSection
                        aboutSection
                        skillsSection
                        interestsSection
                        availabilitySection
                        settingsSection
                        signOutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadEditingData()
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                firebaseManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile Picture
            Circle()
                .fill(Color.appAccent)
                .frame(width: 100, height: 100)
                .overlay(
                    Text(currentUser.name.prefix(1).uppercased())
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.black)
                )
            
            // Name and Info
            VStack(spacing: 8) {
                if isEditing {
                    TextField("Name", text: $editedName)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                } else {
                    Text(currentUser.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.appText)
                }
                
                Text(currentUser.email)
                    .font(.system(size: 16))
                    .foregroundColor(.appSecondary)
                
                Text(currentUser.role.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.appAccent)
                    )
            }
            
            // Edit Button
            if isEditing {
                HStack(spacing: 16) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.appSecondary, lineWidth: 1)
                    )
                    
                    Button("Save") {
                        saveProfile()
                    }
                    .primaryButton()
                }
            } else {
                Button("Edit Profile") {
                    startEditing()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.appText)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.appText, lineWidth: 1)
                )
            }
        }
        .padding(20)
        .glassBackground()
        .padding(.top, 60)
    }
    
    var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Rating",
                value: String(format: "%.1f", currentUser.rating),
                icon: "star.fill"
            )
            
            StatCard(
                title: "Projects",
                value: "\(currentUser.completedProjects)",
                icon: "folder.fill"
            )
            
            StatCard(
                title: "Skills",
                value: "\(currentUser.skills.count)",
                icon: "checkmark.seal.fill"
            )
        }
    }
    
    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appText)
            
            if isEditing {
                TextField("Tell others about yourself...", text: $editedBio, axis: .vertical)
                    .lineLimit(3...6)
            } else {
                Text(currentUser.bio.isEmpty ? "No bio yet" : currentUser.bio)
                    .font(.system(size: 16))
                    .foregroundColor(currentUser.bio.isEmpty ? .appSecondary : .appText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassBackground()
            }
        }
        .padding(20)
        .glassBackground()
    }
    
    var skillsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skills (\(isEditing ? editedSkills.count : currentUser.skills.count))")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appText)
            
            if isEditing {
                HStack {
                    TextField("Add skill", text: $newSkill)
                    
                    Button("Add") {
                        if !newSkill.isEmpty && !editedSkills.contains(newSkill) {
                            editedSkills.append(newSkill)
                            newSkill = ""
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.appAccent)
                    )
                    .disabled(newSkill.isEmpty)
                }
            }
            
            let skills = isEditing ? editedSkills : currentUser.skills
            if skills.isEmpty {
                Text("No skills added yet")
                    .foregroundColor(.appSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(skills, id: \.self) { skill in
                        HStack {
                            Text(skill)
                                .font(.system(size: 12))
                                .foregroundColor(.appText)
                            
                            Spacer()
                            
                            if isEditing {
                                Button(action: {
                                    editedSkills.removeAll { $0 == skill }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appAccent.opacity(0.3))
                        )
                    }
                }
            }
        }
        .padding(20)
        .glassBackground()
    }
    
    var interestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interests (\(isEditing ? editedInterests.count : currentUser.interests.count))")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appText)
            
            if isEditing {
                HStack {
                    TextField("Add interest", text: $newInterest)
                    
                    Button("Add") {
                        if !newInterest.isEmpty && !editedInterests.contains(newInterest) {
                            editedInterests.append(newInterest)
                            newInterest = ""
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.appAccent)
                    )
                    .disabled(newInterest.isEmpty)
                }
            }
            
            let interests = isEditing ? editedInterests : currentUser.interests
            if interests.isEmpty {
                Text("No interests added yet")
                    .foregroundColor(.appSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(interests, id: \.self) { interest in
                        HStack {
                            Text(interest)
                                .font(.system(size: 12))
                                .foregroundColor(.appText)
                            
                            Spacer()
                            
                            if isEditing {
                                Button(action: {
                                    editedInterests.removeAll { $0 == interest }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appAccent.opacity(0.3))
                        )
                    }
                }
            }
        }
        .padding(20)
        .glassBackground()
    }

    var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Availability")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appText)
                
                Spacer()
                
                Button(isEditingAvailability ? "Save" : "Edit") {
                    if isEditingAvailability {
                        saveAvailability()
                    } else {
                        startEditingAvailability()
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isEditingAvailability ? .white : .appText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isEditingAvailability ? Color.filterGreen : Color.backgroundLight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isEditingAvailability ? Color.filterGreen : Color.appSecondary, lineWidth: 1)
                        )
                )
            }
            
            if isEditingAvailability {
                InteractiveAvailabilityEditor(availability: $editedAvailability)
            } else {
                if currentUser.availability.isEmpty {
                    EmptyAvailabilityView {
                        startEditingAvailability()
                    }
                } else {
                    AvailabilityHeatmapView(availability: currentUser.availability)
                }
            }
        }
        .padding(20)
        .glassBackground()
    }

    func startEditingAvailability() {
        // Initialize with current availability or create default schedule
        if currentUser.availability.isEmpty {
            editedAvailability = createDefaultAvailability()
        } else {
            editedAvailability = currentUser.availability
        }
        isEditingAvailability = true
    }

    func saveAvailability() {
        var updatedUser = currentUser
        updatedUser.availability = editedAvailability
        
        // If using APIManager instead of Firebase:
        // apiManager.updateUserAvailability(userId: updatedUser.id, availability: editedAvailability) { result in ... }
        
        // If using Firebase (replace with your manager):
        firebaseManager.saveUserProfile(user: updatedUser) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.isEditingAvailability = false
                case .failure(let error):
                    print("Error saving availability: \(error)")
                    // Handle error - maybe show alert
                }
            }
        }
    }

    func createDefaultAvailability() -> [AvailabilitySlot] {
        var defaultSlots: [AvailabilitySlot] = []
        
        // Create weekday availability (Monday-Friday, 9AM-5PM)
        for day in 1...5 { // Monday = 1, Friday = 5
            let slot = AvailabilitySlot(
                dayOfWeek: day,
                startHour: 9,
                endHour: 17,
                isAvailable: true
            )
            defaultSlots.append(slot)
        }
        
        return defaultSlots
    }

    
    var settingsSection: some View {
        VStack(spacing: 12) {
            SettingsRow(
                icon: "bell.fill",
                title: "Notifications",
                subtitle: "Manage your notifications"
            ) {
                // Handle notifications
            }
            
            SettingsRow(
                icon: "lock.fill",
                title: "Privacy",
                subtitle: "Privacy settings"
            ) {
                // Handle privacy
            }
            
            SettingsRow(
                icon: "questionmark.circle.fill",
                title: "Help & Support",
                subtitle: "Get help"
            ) {
                // Handle help
            }
        }
        .padding(20)
        .glassBackground()
    }
    
    var signOutSection: some View {
        Button("Sign Out") {
            showingSignOutAlert = true
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.red)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.red, lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }
    
    func loadEditingData() {
        editedName = currentUser.name
        editedBio = currentUser.bio
        editedSkills = currentUser.skills
        editedInterests = currentUser.interests
    }
    
    func startEditing() {
        loadEditingData()
        isEditing = true
    }
    
    func cancelEditing() {
        loadEditingData()
        isEditing = false
    }
    
    func saveProfile() {
        var updatedUser = currentUser
        updatedUser.name = editedName
        updatedUser.bio = editedBio
        updatedUser.skills = editedSkills
        updatedUser.interests = editedInterests
        
        firebaseManager.saveUserProfile(user: updatedUser) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.isEditing = false
                case .failure:
                    // Handle error
                    break
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.appText)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.appAccent.opacity(0.2)))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.appSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondary)
            }
            .padding(16)
            .glassBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
}
