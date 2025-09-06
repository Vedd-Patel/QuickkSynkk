//
//  HomeView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//


import SwiftUI

struct HomeView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var matchingEngine = MatchingEngine.shared
    @State private var matches: [MatchResult] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Quick Stats
                        quickStatsSection
                        
                        // Recommended Teammates
                        recommendedSection
                        
                        // Recent Activity
                        activitySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadMatches()
        }
    }
    
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Good Morning,")
                    .font(.system(size: 16))
                    .foregroundColor(.appSecondary)
                
                Text(firebaseManager.currentUser?.name ?? "User")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appText)
            }
            
            Spacer()
            
            Button(action: {}) {
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(firebaseManager.currentUser?.name.prefix(1).uppercased() ?? "U")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    )
            }
        }
        .padding(.top, 60)
    }
    
    var quickStatsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Matches",
                value: "\(matches.count)",
                icon: "person.2.fill"
            )
            
            StatCard(
                title: "Teams",
                value: "3",
                icon: "person.3.fill"
            )
            
            StatCard(
                title: "Projects",
                value: "5",
                icon: "folder.fill"
            )
        }
    }
    
    var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended Teammates")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appText)
                
                Spacer()
                
                Button("See all") {
                    // Navigate to discover
                }
                .foregroundColor(.appSecondary)
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 200)
            } else if matches.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    title: "No matches yet",
                    subtitle: "Complete your profile to find teammates"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(matches.prefix(5)) { match in
                            TeammateCard(match: match) {
                                sendCollaborationRequest(to: match.user)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
        }
    }
    
    var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.appText)
            
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "person.badge.plus",
                    title: "New teammate match",
                    subtitle: "2 hours ago"
                )
                
                ActivityRow(
                    icon: "message.fill",
                    title: "Collaboration request",
                    subtitle: "5 hours ago"
                )
                
                ActivityRow(
                    icon: "star.fill",
                    title: "Project completed",
                    subtitle: "1 day ago"
                )
            }
        }
    }
    
    func loadMatches() {
        guard let currentUser = firebaseManager.currentUser else { return }
        
        firebaseManager.fetchAllUsers { result in
            switch result {
            case .success(let users):
                self.matches = self.matchingEngine.findMatches(for: currentUser, from: users)
                self.isLoading = false
            case .failure:
                self.isLoading = false
            }
        }
    }
    
    func sendCollaborationRequest(to user: User) {
        guard let currentUser = firebaseManager.currentUser,
              let currentUserId = currentUser.id,
              let targetUserId = user.id else { return }
        
        let request = CollaborationRequest(
            fromUserId: currentUserId,
            toUserId: targetUserId,
            message: "Hi \(user.name)! Let's collaborate!",
            status: .pending,
            createdAt: Date(),
            requestType: .directCollaboration
        )
        
        firebaseManager.sendCollaborationRequest(request: request) { _ in
            // Handle result
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.appText)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appText)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .glassBackground()
    }
}

struct TeammateCard: View {
    let match: MatchResult
    let onConnect: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.appAccent)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(match.user.name.prefix(1).uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                )
            
            VStack(spacing: 8) {
                Text(match.user.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appText)
                
                Text("\(Int(match.matchScore * 100))% match")
                    .font(.system(size: 12))
                    .foregroundColor(.appSecondary)
                
                if !match.sharedSkills.isEmpty {
                    Text(match.sharedSkills.first ?? "")
                        .font(.system(size: 10))
                        .foregroundColor(.appText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.appAccent)
                        )
                }
            }
            
            Button("Connect") {
                onConnect()
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.appAccent)
            )
        }
        .frame(width: 140)
        .padding(16)
        .glassBackground()
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appText)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.appAccent))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appText)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .glassBackground()
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.appSecondary)
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appText)
            
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
    }
}

#Preview {
    HomeView()
}
