//
//  TeamsView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//

import SwiftUI

struct TeamsView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var teams: [Team] = []
    @State private var showingCreateTeam = false
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var selectedTab: TeamTab = .all

    enum TeamTab: String, CaseIterable {
        case all = "All Teams"
        case my  = "My Teams"

        var icon: String {
            switch self {
            case .all: return "person.3"
            case .my:  return "person.crop.circle"
            }
        }
    }

    var filteredTeams: [Team] {
        let target = selectedTab == .all ? teams : myTeams
        guard !searchText.isEmpty else { return target }
        return target.filter { team in
            team.name.localizedCaseInsensitiveContains(searchText) ||
            team.description.localizedCaseInsensitiveContains(searchText) ||
            team.requiredSkills.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var myTeams: [Team] {
        guard let currentId = firebaseManager.currentUser?.id else { return [] }
        return teams.filter { team in
            team.createdBy == currentId ||
            team.currentMembers.contains { $0.userId == currentId }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection
                    tabSection
                    searchSection

                    if isLoading {
                        loadingView
                    } else if filteredTeams.isEmpty {
                        emptyStateView
                    } else {
                        teamsListView
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateTeam) {
                CreateTeamView()
            }
            .onAppear { loadTeams() }
        }
    }

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Teams")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appText)
                Text("Join or create your team")
                    .font(.system(size: 16))
                    .foregroundColor(.appSecondary)
            }
            Spacer()
            Button {
                showingCreateTeam = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.appAccent))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    var tabSection: some View {
        HStack(spacing: 0) {
            ForEach(TeamTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                        Text(tab.rawValue)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedTab == tab ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(selectedTab == tab ? Color.appAccent : Color.clear)
                    )
                }
            }
        }
        .padding(4)
        .glassBackground()
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appSecondary)
                .font(.system(size: 18))
            TextField("Search teams...", text: $searchText)
                .foregroundColor(.appText)
                .font(.system(size: 16))
            if !searchText.isEmpty {
                Button("Clear") { searchText = "" }
                    .foregroundColor(.appSecondary)
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassBackground()
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .filterBlue))
            Text("Loading teams...")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appText)
            Spacer()
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: selectedTab == .all ? "person.3.slash" : "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.appSecondary)
            Text(selectedTab == .all ? "No teams found" : "No teams yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appText)
            Text(selectedTab == .all
                 ? "Try a different search term"
                 : "Create your first team!")
                .font(.system(size: 16))
                .foregroundColor(.appSecondary)
            if selectedTab == .my {
                Button("Create Team") {
                    showingCreateTeam = true
                }
                .primaryButton()
                .frame(width: 200)
            }
            Spacer()
        }
    }

    var teamsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredTeams) { team in
                    TeamCard(team: team) {
                        requestToJoin(team)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    func loadTeams() {
        isLoading = true
        firebaseManager.fetchTeams { result in
            DispatchQueue.main.async {
                isLoading = false
                if case .success(let fetched) = result {
                    teams = fetched
                }
            }
        }
    }

    func requestToJoin(_ team: Team) {
        guard
            let currentUser = firebaseManager.currentUser,
            let userId = currentUser.id,
            let teamId = team.id
        else { return }
        let request = CollaborationRequest(
            fromUserId: userId,
            toUserId: team.createdBy,
            message: "Hi! I'd like to join '\(team.name)'. My skills: \(currentUser.skills.prefix(3).joined(separator: ", "))",
            status: .pending,
            createdAt: Date(),
            requestType: .teamJoin
        )
        firebaseManager.sendCollaborationRequest(request: request) { _ in }
    }
}

struct TeamCard: View {
    let team: Team
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(team.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appText)
                    HStack(spacing: 16) {
                        Label("\(team.currentMembers.count)/\(team.maxMembers)", systemImage: "person.2")
                        Label(team.projectType.rawValue, systemImage: "folder")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.appSecondary)
                }
                Spacer()
                StatusBadge(status: team.status)
            }
            Text(team.description)
                .font(.system(size: 14))
                .foregroundColor(.appText)
                .lineLimit(3)
            if !team.requiredSkills.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(team.requiredSkills.prefix(5), id: \.self) { skill in
                            Text(skill)
                                .font(.system(size: 10))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.appAccent))
                        }
                    }
                }
            }
            if team.status == .recruiting {
                Button("Join Team", action: onJoin)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.appAccent))
            }
        }
        .padding(20)
        .glassBackground()
    }
}

struct StatusBadge: View {
    let status: TeamStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(statusColor.opacity(0.2)))
    }

    private var statusColor: Color {
        switch status {
        case .recruiting: return .green
        case .full:        return .orange
        case .active:      return .blue
        case .completed:   return .purple
        case .paused:      return .gray
        case .onHold:      return .red
        }
    }
}

struct TeamsView_Previews: PreviewProvider {
    static var previews: some View {
        TeamsView()
    }
}
