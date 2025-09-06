//
//  DiscoverView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//


import SwiftUI

struct DiscoverView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var matches: [MatchResult] = []
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var selectedSkillFilter = ""
    @State private var availableSkills: [String] = []
    @State private var isLoading = true
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case skillMatch = "By Skill"
        case highRated = "Highly Rated"
        case available = "Available Now"
        
        var icon: String {
            switch self {
            case .all: return "person.3"
            case .skillMatch: return "checkmark.seal"
            case .highRated: return "star.fill"
            case .available: return "clock.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .appSecondary
            case .skillMatch: return .filterGreen
            case .highRated: return .filterOrange
            case .available: return .filterBlue
            }
        }
    }
    
    var filteredUsers: [User] {
        var filtered = firebaseManager.allUsers
        
        // Remove current user from results
        if let currentUserId = firebaseManager.currentUser?.id {
            filtered = filtered.filter { $0.id != currentUserId }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.skills.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                user.interests.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply skill filter
        if !selectedSkillFilter.isEmpty {
            filtered = filtered.filter { user in
                user.skills.contains(selectedSkillFilter)
            }
        }
        
        // Apply other filters
        switch selectedFilter {
        case .all:
            break
        case .skillMatch:
            // Show users with any matching skills
            if let currentUser = firebaseManager.currentUser {
                filtered = filtered.filter { user in
                    !Set(user.skills).intersection(Set(currentUser.skills)).isEmpty
                }
            }
        case .highRated:
            filtered = filtered.filter { $0.rating >= 4.0 }
        case .available:
            filtered = filtered.filter { !$0.availability.isEmpty }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection
                    searchSection
                    skillFilterSection
                    filterSection
                    
                    if isLoading {
                        loadingView
                    } else if filteredUsers.isEmpty {
                        emptyStateView
                    } else {
                        usersListView
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadUsers()
            extractAvailableSkills()
        }
        .refreshable {
            loadUsers()
        }
    }
    
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Discover Teammates")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appText)
                
                Text("Find collaborators based on skills and interests")
                    .font(.system(size: 16))
                    .foregroundColor(.appSecondary)
            }
            
            Spacer()
            
            Button(action: loadUsers) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.filterBlue)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.backgroundLight))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appSecondary)
                .font(.system(size: 18))
            
            TextField("Search by name, skills, interests...", text: $searchText)
                .foregroundColor(.appText)
                .font(.system(size: 16))
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .foregroundColor(.filterBlue)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.backgroundLight)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appSecondary, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    var skillFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filter by Skill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appText)
                
                Spacer()
                
                if !selectedSkillFilter.isEmpty {
                    Button("Clear") {
                        selectedSkillFilter = ""
                    }
                    .foregroundColor(.filterRed)
                    .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableSkills.prefix(10), id: \.self) { skill in
                        Button(skill) {
                            selectedSkillFilter = selectedSkillFilter == skill ? "" : skill
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedSkillFilter == skill ? .white : .appText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedSkillFilter == skill ? Color.filterGreen : Color.backgroundLight)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.filterGreen, lineWidth: selectedSkillFilter == skill ? 0 : 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
    }
    
    var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: getFilterCount(filter)
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
    
    var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .filterBlue))
            Text("Finding teammates...")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appText)
            Text("Loading from Firebase users collection")
                .font(.system(size: 14))
                .foregroundColor(.appSecondary)
            Spacer()
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "person.3.slash")
                .font(.system(size: 60))
                .foregroundColor(.appSecondary)
            
            Text("No teammates found")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appText)
            
            Text("Try adjusting your search filters or check back later")
                .font(.system(size: 16))
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
            
            Button("Refresh") {
                loadUsers()
            }
            .primaryButton()
            .frame(width: 150)
            
            Spacer()
        }
    }
    
    var usersListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredUsers) { user in
                    UserDiscoveryCard(user: user) {
                        sendCollaborationRequest(to: user)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    func getFilterCount(_ filter: FilterType) -> Int {
        switch filter {
        case .all:
            return firebaseManager.allUsers.count
        case .skillMatch:
            if let currentUser = firebaseManager.currentUser {
                return firebaseManager.allUsers.filter { user in
                    !Set(user.skills).intersection(Set(currentUser.skills)).isEmpty
                }.count
            }
            return 0
        case .highRated:
            return firebaseManager.allUsers.filter { $0.rating >= 4.0 }.count
        case .available:
            return firebaseManager.allUsers.filter { !$0.availability.isEmpty }.count
        }
    }
    
    func loadUsers() {
        print("👥 Loading users from Firebase...")
        isLoading = true
        
        firebaseManager.fetchAllUsers { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let users):
                    print("✅ Loaded \(users.count) users for discovery")
                case .failure(let error):
                    print("❌ Failed to load users: \(error)")
                }
            }
        }
    }
    
    func extractAvailableSkills() {
        let allSkills = firebaseManager.allUsers.flatMap { $0.skills }
        let uniqueSkills = Array(Set(allSkills)).sorted()
        availableSkills = uniqueSkills
    }
    
    func sendCollaborationRequest(to user: User) {
        guard let currentUser = firebaseManager.currentUser,
              let currentUserId = currentUser.id,
              let targetUserId = user.id else { return }
        
        let request = CollaborationRequest(
            fromUserId: currentUserId,
            toUserId: targetUserId,
            message: "Hi \(user.name)! I'd love to collaborate with you based on our shared skills and interests.",
            status: .pending,
            createdAt: Date(),
            requestType: .directCollaboration
        )
        
        firebaseManager.sendCollaborationRequest(request: request) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    print("✅ \(message)")
                case .failure(let error):
                    print("❌ Failed to send request: \(error)")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let filter: DiscoverView.FilterType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : filter.color)
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .appText)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? filter.color : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white : filter.color)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? filter.color : Color.cardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(filter.color, lineWidth: 2)
            )
        }
    }
}

struct UserDiscoveryCard: View {
    let user: User
    let onConnect: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 16) {
                // Profile Picture Placeholder
                Circle()
                    .fill(Color.filterBlue)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(user.name.prefix(1).uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(user.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appText)
                    
                    Text("\(user.role.rawValue) • \(user.experience.rawValue)")
                        .font(.system(size: 14))
                        .foregroundColor(.appSecondary)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.filterOrange)
                            .font(.system(size: 12))
                        
                        Text(String(format: "%.1f", user.rating))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.filterOrange)
                        
                        Text("• \(user.completedProjects) projects")
                            .font(.system(size: 12))
                            .foregroundColor(.appSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.backgroundLight)
                    .cornerRadius(12)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button("Connect") {
                        onConnect()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.filterGreen)
                    .cornerRadius(20)
                    
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.filterBlue)
                            .padding(8)
                            .background(Color.backgroundLight)
                            .clipShape(Circle())
                    }
                }
            }
            
            // Bio
            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.system(size: 14))
                    .foregroundColor(.appText)
                    .lineLimit(isExpanded ? nil : 2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.backgroundLight)
                    .cornerRadius(12)
            }
            
            // Skills
            if !user.skills.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skills")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(user.skills.prefix(isExpanded ? user.skills.count : 6), id: \.self) { skill in
                            Text(skill)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.filterGreen)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.backgroundLight)
                .cornerRadius(12)
            }
            
            // Interests (show when expanded)
            if isExpanded && !user.interests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interests")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(user.interests, id: \.self) { interest in
                            Text(interest)
                                .font(.system(size: 11))
                                .foregroundColor(.appText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.buttonUnselected)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.filterPurple, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.backgroundLight)
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .cardStyle()
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

#Preview {
    DiscoverView()
}
