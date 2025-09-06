//
//  OnboardingView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//


import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var currentStep = 0
    @State private var selectedInterests: Set<String> = []
    @State private var selectedSkills: Set<String> = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var completionAttempts = 0
    
    let totalSteps = 2
    
    let interests = [
        "Hackathon", "Designathon", "Group Projects", "Event Management",
        "Clean-up Drive", "Games", "Coding Competition", "Workshop"
    ]
    
    let skills = [
        "AI/ML", "Web Development", "UI/UX", "App Development", "Graphic Design",
        "Football", "Event organising", "Cricket", "3D Designer",
        "Backend Development", "Blockchain", "BGMI"
    ]
    
    var body: some View {
        ZStack {
            // Solid Background Gradient
            LinearGradient(
                colors: [
                    Color.backgroundDark,
                    Color.backgroundMedium,
                    Color.backgroundDark
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if isLoading {
                loadingOverlay
            } else {
                mainContent
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("Try Again") {
                retryCompletion()
            }
            Button("Skip Setup") {
                forceCompleteOnboarding()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    var loadingOverlay: some View {
        ZStack {
            Color.backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appAccent)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.black)
                    )
                    .scaleEffect(isLoading ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isLoading)
                
                VStack(spacing: 12) {
                    Text("Setting up your profile...")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("This should only take a moment")
                        .font(.system(size: 16))
                        .foregroundColor(.backgroundLight)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.top, 8)
                }
                
                if completionAttempts > 0 {
                    Button("Skip Setup & Continue") {
                        forceCompleteOnboarding()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 2)
                            .background(Color.filterBlue)
                    )
                    .cornerRadius(20)
                }
            }
            .padding(32)
            .background(Color.cardBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.appSecondary, lineWidth: 2)
            )
            .padding(.horizontal, 40)
        }
    }
    
    var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appAccent)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    )
                
                Spacer()
                
                Button("Skip") {
                    skipOnboarding()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.backgroundLight)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            Spacer()
            
            // Content
            VStack(spacing: 40) {
                if currentStep == 0 {
                    interestsStep
                } else {
                    skillsStep
                }
            }
            
            Spacer()
            
            // Next Button - More Visible
            Button(action: nextStep) {
                HStack {
                    Text(currentStep == totalSteps - 1 ? "COMPLETE SETUP" : "NEXT")
                        .font(.system(size: 18, weight: .bold))
                    
                    if currentStep < totalSteps - 1 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.appAccent)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.filterGreen, lineWidth: 3)
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .disabled(!canProceed)
            .scaleEffect(canProceed ? 1.0 : 0.95)
            .background(
                canProceed ? Color.clear : Color.gray
            )
        }
    }
    
    var interestsStep: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Which events excite you?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Select your interests (Step 1 of 2)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.backgroundLight)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(interests, id: \.self) { interest in
                    Button(interest) {
                        toggleSelection(item: interest, in: &selectedInterests)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selectedInterests.contains(interest) ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedInterests.contains(interest) ? Color.appAccent : Color.buttonUnselected)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                selectedInterests.contains(interest) ? Color.filterGreen : Color.backgroundLight,
                                lineWidth: 2
                            )
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    var skillsStep: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What are your skills?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Select your skills (Step 2 of 2)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.backgroundLight)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(skills, id: \.self) { skill in
                    Button(skill) {
                        toggleSelection(item: skill, in: &selectedSkills)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selectedSkills.contains(skill) ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedSkills.contains(skill) ? Color.appAccent : Color.buttonUnselected)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                selectedSkills.contains(skill) ? Color.filterBlue : Color.backgroundLight,
                                lineWidth: 2
                            )
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    var canProceed: Bool {
        switch currentStep {
        case 0: return !selectedInterests.isEmpty
        case 1: return !selectedSkills.isEmpty
        default: return false
        }
    }
    
    func toggleSelection(item: String, in set: inout Set<String>) {
        if set.contains(item) {
            set.remove(item)
        } else {
            set.insert(item)
        }
    }
    
    func nextStep() {
        print("📱 Next step pressed - Current: \(currentStep)")
        
        if currentStep < totalSteps - 1 {
            withAnimation(.spring()) {
                currentStep += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    func skipOnboarding() {
        print("⏭️ Skipping onboarding")
        selectedInterests = Set(["General"])
        selectedSkills = Set(["General"])
        completeOnboarding()
    }
    
    func completeOnboarding() {
        print("🎯 Starting onboarding completion...")
        print("   Selected interests: \(selectedInterests)")
        print("   Selected skills: \(selectedSkills)")
        print("   Completion attempts: \(completionAttempts)")
        
        guard !isLoading else {
            print("⚠️ Already completing onboarding, ignoring")
            return
        }
        
        completionAttempts += 1
        
        guard let authUser = Auth.auth().currentUser else {
            print("❌ No authenticated user found")
            errorMessage = "Authentication error. Please sign in again."
            showError = true
            return
        }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if self.isLoading {
                print("⏰ Onboarding completion timeout")
                self.isLoading = false
                self.errorMessage = "Setup is taking too long. Please try again."
                self.showError = true
            }
        }
        
        var userProfile = firebaseManager.currentUser ?? User(
            id: authUser.uid,
            name: authUser.displayName ?? "User",
            email: authUser.email ?? ""
        )
        
        userProfile.interests = Array(selectedInterests)
        userProfile.skills = Array(selectedSkills)
        
        print("💾 Saving profile:")
        print("   ID: \(userProfile.id ?? "nil")")
        print("   Name: \(userProfile.name)")
        print("   Interests: \(userProfile.interests)")
        print("   Skills: \(userProfile.skills)")
        
        firebaseManager.saveUserProfile(user: userProfile) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success():
                    print("✅ Profile saved successfully!")
                    self.firebaseManager.currentUser = userProfile
                    
                case .failure(let error):
                    print("❌ Failed to save profile: \(error)")
                    self.errorMessage = "Failed to save your profile. Please try again."
                    self.showError = true
                }
            }
        }
    }
    
    func retryCompletion() {
        completeOnboarding()
    }
    
    func forceCompleteOnboarding() {
        print("🚀 Force completing onboarding")
        
        guard let authUser = Auth.auth().currentUser else { return }
        
        let minimalProfile = User(
            id: authUser.uid,
            name: authUser.displayName ?? "User",
            email: authUser.email ?? ""
        )
        
        var finalProfile = minimalProfile
        finalProfile.skills = selectedSkills.isEmpty ? ["General"] : Array(selectedSkills)
        finalProfile.interests = selectedInterests.isEmpty ? ["General"] : Array(selectedInterests)
        
        firebaseManager.currentUser = finalProfile
        
        firebaseManager.saveUserProfile(user: finalProfile) { _ in
            print("✅ Background save completed")
        }
    }
}

#Preview {
    OnboardingView()
}
