//
//  MainTabView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//


import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            DiscoverView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "magnifyingglass" : "magnifyingglass")
                    Text("Discover")
                }
                .tag(1)
            
            TeamsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.3.fill" : "person.3")
                    Text("Teams")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.appText)
    }
}

#Preview {
    MainTabView()
}
