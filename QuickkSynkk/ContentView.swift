//
//  ContentView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var hasShownOnboarding = false
    
    var body: some View {
        Group {
            if firebaseManager.connectionError {
                ConnectionErrorView()
            } else if firebaseManager.isLoading && !hasShownOnboarding {
                LoadingView()
            } else if !firebaseManager.isAuthenticated {
                LoginView()
                    .onAppear {
                        print("🔐 Showing LoginView")
                        hasShownOnboarding = false
                    }
            } else if let user = firebaseManager.currentUser {
                if shouldShowOnboarding(user: user) {
                    OnboardingView()
                        .onAppear {
                            print("🎯 Showing OnboardingView")
                            print("   Skills empty: \(user.skills.isEmpty)")
                            print("   Interests empty: \(user.interests.isEmpty)")
                            hasShownOnboarding = true
                        }
                } else {
                    MainTabView()
                        .onAppear {
                            print("✅ Showing MainTabView")
                            print("   Skills: \(user.skills)")
                            print("   Interests: \(user.interests)")
                        }
                }
            } else {
                LoadingView()
                    .onAppear {
                        print("⏳ Waiting for user profile")
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: firebaseManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: firebaseManager.currentUser?.skills.isEmpty)
        .animation(.easeInOut(duration: 0.3), value: firebaseManager.currentUser?.interests.isEmpty)
    }
    
    func shouldShowOnboarding(user: User) -> Bool {
        let needsOnboarding = user.skills.isEmpty || user.interests.isEmpty
        print("👤 User onboarding check:")
        print("   Skills: \(user.skills)")
        print("   Interests: \(user.interests)")
        print("   Needs onboarding: \(needsOnboarding)")
        return needsOnboarding
    }
}

struct LoadingView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showSkipButton = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appAccent)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.black)
                    )
                
                Text("QuickSync")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.appText)
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .appText))
                    
                    Text("Setting up your account...")
                        .font(.system(size: 16))
                        .foregroundColor(.appSecondary)
                }
                
                if showSkipButton {
                    Button("Continue") {
                        firebaseManager.skipLoading()
                    }
                    .primaryButton()
                    .frame(width: 150)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showSkipButton = true
                }
            }
        }
    }
}

struct ConnectionErrorView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 80))
                    .foregroundColor(.appSecondary)
                
                VStack(spacing: 16) {
                    Text("Connection Issue")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.appText)
                    
                    Text("Please check your internet connection")
                        .font(.system(size: 16))
                        .foregroundColor(.appSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    Button("Retry") {
                        firebaseManager.retryConnection()
                    }
                    .primaryButton()
                    .frame(width: 150)
                    
                    Button("Continue Offline") {
                        firebaseManager.skipLoading()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appText)
                    .frame(width: 150, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.appText, lineWidth: 2)
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
