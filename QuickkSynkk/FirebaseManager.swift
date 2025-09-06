//
//  FirebaseManager.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var allUsers: [User] = []
    @Published var allTeams: [Team] = []
    @Published var allEvents: [Event] = []
    @Published var recommendations: [UserRecommendation] = []
    @Published var collaborationRequests: [CollaborationRequest] = []
    @Published var isLoading = false
    @Published var connectionError = false
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let smartRecommendationEngine = SmartRecommendationEngine()
    
    init() {
        checkAuthStatus()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Authentication
    func checkAuthStatus() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.loadUserProfile(userId: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isLoading = false
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("📝 Starting sign up for: \(email)")
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("❌ Sign up error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let userId = result?.user.uid else {
                completion(.failure(NSError(domain: "SignUp", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID"])))
                return
            }
            
            print("✅ User created with ID: \(userId)")
            
            // Create user with empty skills and interests (will trigger onboarding)
            let user = User(id: userId, name: name, email: email)
            
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isLoading = false
            }
            
            // Save basic profile to users collection
            self?.saveUserProfile(user: user) { saveResult in
                switch saveResult {
                case .success:
                    print("✅ Basic user profile saved to users collection")
                    completion(.success(userId))
                case .failure(let error):
                    print("❌ Failed to save user profile: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("🔐 Signing in: \(email)")
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ Sign in error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let userId = result?.user.uid else {
                completion(.failure(NSError(domain: "SignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID"])))
                return
            }
            
            print("✅ User signed in with ID: \(userId)")
            completion(.success(userId))
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isLoading = false
                self.connectionError = false
            }
            print("✅ User signed out")
        } catch {
            print("❌ Sign out error: \(error)")
        }
    }
    
    // MARK: - User Profile Management
    func saveUserProfile(user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = user.id else {
            completion(.failure(NSError(domain: "SaveUser", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is required"])))
            return
        }
        
        print("💾 Saving user profile to users collection for: \(userId)")
        
        do {
            let userData = try Firestore.Encoder().encode(user)
            
            // Save to users collection
            db.collection("users").document(userId).setData(userData, merge: true) { [weak self] error in
                if let error = error {
                    print("❌ Failed to save user profile: \(error)")
                    completion(.failure(error))
                } else {
                    print("✅ User profile saved successfully to users collection")
                    DispatchQueue.main.async {
                        self?.currentUser = user
                    }
                    
                    // Update user_skills collection for searching
                    self?.updateUserSkillsIndex(userId: userId, skills: user.skills)
                    
                    // Create analytics entry
                    self?.updateAnalytics(userId: userId, user: user)
                    
                    // Generate recommendations if user has skills and interests
                    if !user.skills.isEmpty && !user.interests.isEmpty {
                        self?.generateSmartRecommendations(for: user)
                    }
                    
                    completion(.success(()))
                }
            }
        } catch {
            print("❌ Failed to encode user: \(error)")
            completion(.failure(error))
        }
    }
    
    func loadUserProfile(userId: String) {
        print("📖 Loading user profile from users collection: \(userId)")
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            
            if let error = error {
                print("❌ Error loading user profile: \(error)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("❌ No user data found, creating basic profile")
                self?.createBasicUserProfile(userId: userId)
                return
            }
            
            do {
                var user = try Firestore.Decoder().decode(User.self, from: data)
                user.id = userId
                print("✅ User profile loaded from users collection: \(user.name)")
                DispatchQueue.main.async {
                    self?.currentUser = user
                    self?.connectionError = false
                }
                
                // Load additional data
                self?.loadRecommendations(for: userId)
                self?.loadCollaborationRequests(for: userId)
                
            } catch {
                print("❌ Error decoding user: \(error)")
                self?.createBasicUserProfile(userId: userId)
            }
        }
    }
    
    private func createBasicUserProfile(userId: String) {
        guard let authUser = Auth.auth().currentUser else { return }
        
        let basicUser = User(
            id: userId,
            name: authUser.displayName ?? "User",
            email: authUser.email ?? ""
        )
        
        print("🆕 Creating basic user profile in users collection")
        DispatchQueue.main.async {
            self.currentUser = basicUser
        }
        
        // Save to users collection
        saveUserProfile(user: basicUser) { _ in }
    }
    
    // MARK: - User Skills Index Management
    private func updateUserSkillsIndex(userId: String, skills: [String]) {
        print("🔍 Updating user_skills collection for user: \(userId)")
        
        let batch = db.batch()
        
        for skill in skills {
            let skillDocId = skill.lowercased().replacingOccurrences(of: " ", with: "_")
            let skillRef = db.collection("user_skills").document(skillDocId)
            
            batch.setData([
                "skill_name": skill,
                "users": FieldValue.arrayUnion([userId]),
                "updated_at": FieldValue.serverTimestamp()
            ], forDocument: skillRef, merge: true)
        }
        
        batch.commit { error in
            if let error = error {
                print("❌ Failed to update user_skills: \(error)")
            } else {
                print("✅ Updated user_skills collection")
            }
        }
    }
    
    // MARK: - Analytics Management
    private func updateAnalytics(userId: String, user: User) {
        print("📊 Updating analytics collection for user: \(userId)")
        
        db.collection("analytics").document(userId).setData([
            "user_id": userId,
            "name": user.name,
            "email": user.email,
            "skills_count": user.skills.count,
            "interests_count": user.interests.count,
            "profile_completed": !user.skills.isEmpty && !user.interests.isEmpty,
            "last_updated": FieldValue.serverTimestamp(),
            "join_date": user.joinedDate
        ], merge: true) { error in
            if let error = error {
                print("❌ Failed to update analytics: \(error)")
            } else {
                print("✅ Updated analytics collection")
            }
        }
    }
    
    // MARK: - Skill-based Search
    func searchUsersBySkill(skill: String, completion: @escaping (Result<[User], Error>) -> Void) {
        print("🔍 Searching users with skill: \(skill) in users collection")
        
        db.collection("users")
            .whereField("skills", arrayContains: skill)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error searching users by skill: \(error)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 No users found with skill: \(skill)")
                    completion(.success([]))
                    return
                }
                
                let users = documents.compactMap { doc -> User? in
                    var user = try? Firestore.Decoder().decode(User.self, from: doc.data())
                    user?.id = doc.documentID
                    return user
                }
                
                print("✅ Found \(users.count) users with skill: \(skill)")
                completion(.success(users))
            }
    }
    
    func searchUsersByMultipleSkills(skills: [String], completion: @escaping (Result<[User], Error>) -> Void) {
        print("🔍 Searching users with multiple skills: \(skills)")
        
        db.collection("users")
            .whereField("skills", arrayContainsAny: skills)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let users = documents.compactMap { doc -> User? in
                    var user = try? Firestore.Decoder().decode(User.self, from: doc.data())
                    user?.id = doc.documentID
                    return user
                }
                
                print("✅ Found \(users.count) users with multiple skills")
                completion(.success(users))
            }
    }
    
    func fetchAllUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        print("👥 Fetching all users from users collection")
        
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching users: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let users = documents.compactMap { doc -> User? in
                var user = try? Firestore.Decoder().decode(User.self, from: doc.data())
                user?.id = doc.documentID
                return user
            }
            
            print("✅ Fetched \(users.count) users from users collection")
            completion(.success(users))
        }
    }
    
    // MARK: - Team Management
    func createTeam(team: Team, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = currentUser?.id else {
            completion(.failure(NSError(domain: "CreateTeam", code: -1, userInfo: nil)))
            return
        }
        let teamRef = db.collection("teams").document()
        let teamId = teamRef.documentID

        var t = team
        t.id = teamId
        t.createdBy = userId
        t.createdAt = Date()

        do {
            let data = try Firestore.Encoder().encode(t)
            teamRef.setData(data) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // Add creator as first member
                    self.joinTeam(teamId: teamId) { result in
                        switch result {
                        case .success:
                            break
                        case .failure(let error):
                            print("Error adding creator to team:", error)
                        }
                    }
                    completion(.success(teamId))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    
    func fetchTeams(completion: @escaping (Result<[Team], Error>) -> Void) {
        print("📋 Fetching teams from teams collection")
        
        db.collection("teams")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching teams: \(error)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let teams = documents.compactMap { doc -> Team? in
                    var team = try? Firestore.Decoder().decode(Team.self, from: doc.data())
                    team?.id = doc.documentID
                    return team
                }
                
                print("✅ Fetched \(teams.count) teams from teams collection")
                completion(.success(teams))
            }
    }
    
    // In FirebaseManager.swift, make sure your joinTeam function matches this signature:

    func joinTeam(teamId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = currentUser?.id,
              let userName = currentUser?.name else {
            completion(.failure(NSError(domain: "JoinTeam", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let batch = db.batch()
        
        // 1. Add user to team members subcollection
        let memberRef = db.collection("teams").document(teamId).collection("members").document(userId)
        batch.setData([
            "user_id": userId,
            "name": userName,
            "role": "Member",
            "joined_at": FieldValue.serverTimestamp(),
            "skills": currentUser?.skills ?? []
        ], forDocument: memberRef)
        
        // 2. Update team status if needed
        let teamRef = db.collection("teams").document(teamId)
        batch.updateData([
            "member_count": FieldValue.increment(Int64(1)),
            "last_updated": FieldValue.serverTimestamp()
        ], forDocument: teamRef)
        
        // 3. Update user analytics
        if let userId = currentUser?.id {
            let analyticsRef = db.collection("analytics").document(userId)
            batch.updateData([
                "teams_joined": FieldValue.increment(Int64(1)),
                "last_active": FieldValue.serverTimestamp()
            ], forDocument: analyticsRef)
        }
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Successfully joined team!"))
            }
        }
    }

//    private func joinTeamAsMember(teamId: String, userId: String, role: String) {
//        guard let currentUser = currentUser else { return }
//        
//        let memberData: [String: Any] = [
//            "user_id": userId,
//            "name": currentUser.name,
//            "role": role,
//            "joined_at": FieldValue.serverTimestamp(),
//            "skills": currentUser.skills
//        ]
//        
//        db.collection("teams").document(teamId).collection("members").document(userId)
//            .setData(memberData) { error in
//                if let error = error {
//                    print("❌ Failed to add member to team: \(error)")
//                } else {
//                    print("✅ Added member to team: \(teamId)")
//                }
//            }
//    }
    
    // MARK: - Event Management
    func createEvent(event: Event, completion: @escaping (Result<String, Error>) -> Void) {
        print("📅 Creating event in events collection: \(event.title)")
        
        let eventRef = db.collection("events").document()
        let eventId = eventRef.documentID
        
        var eventToSave = event
        eventToSave.id = eventId
        eventToSave.createdAt = Date()
        
        do {
            let eventData = try Firestore.Encoder().encode(eventToSave)
            eventRef.setData(eventData) { error in
                if let error = error {
                    print("❌ Failed to create event: \(error)")
                    completion(.failure(error))
                } else {
                    print("✅ Event created in events collection: \(eventId)")
                    completion(.success(eventId))
                }
            }
        } catch {
            print("❌ Failed to encode event: \(error)")
            completion(.failure(error))
        }
    }
    
    func fetchAllEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
        print("📅 Fetching events from events collection")
        
        db.collection("events")
            .order(by: "startDate", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching events: \(error)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let events = documents.compactMap { doc -> Event? in
                    var event = try? Firestore.Decoder().decode(Event.self, from: doc.data())
                    event?.id = doc.documentID
                    return event
                }
                
                print("✅ Fetched \(events.count) events from events collection")
                completion(.success(events))
            }
    }
    
    // MARK: - Collaboration Management
    func sendCollaborationRequest(request: CollaborationRequest, completion: @escaping (Result<String, Error>) -> Void) {
        print("🤝 Sending collaboration request to collaboration collection")
        
        let requestRef = db.collection("collaboration").document()
        var requestToSave = request
        requestToSave.id = requestRef.documentID
        requestToSave.createdAt = Date()
        
        do {
            let requestData = try Firestore.Encoder().encode(requestToSave)
            requestRef.setData(requestData) { error in
                if let error = error {
                    print("❌ Failed to send collaboration request: \(error)")
                    completion(.failure(error))
                } else {
                    print("✅ Collaboration request sent to collaboration collection")
                    completion(.success("Request sent successfully!"))
                }
            }
        } catch {
            print("❌ Failed to encode collaboration request: \(error)")
            completion(.failure(error))
        }
    }
    
    func loadCollaborationRequests(for userId: String) {
        print("📨 Loading collaboration requests from collaboration collection")
        
        db.collection("collaboration")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let requests = documents.compactMap { doc -> CollaborationRequest? in
                    var request = try? Firestore.Decoder().decode(CollaborationRequest.self, from: doc.data())
                    request?.id = doc.documentID
                    return request
                }
                
                DispatchQueue.main.async {
                    self?.collaborationRequests = requests
                }
                
                print("✅ Loaded \(requests.count) collaboration requests")
            }
    }
    
    // MARK: - Smart Recommendations
    func generateSmartRecommendations(for user: User) {
        guard let userId = user.id else { return }
        
        print("🧠 Generating smart recommendations for user: \(userId)")
        
        smartRecommendationEngine.generateRecommendations(
            userSkills: user.skills,
            userInterests: user.interests,
            userExperience: user.experience.rawValue,
            userRole: user.role.rawValue
        ) { [weak self] result in
            switch result {
            case .success(let recommendations):
                self?.saveRecommendations(userId: userId, recommendations: recommendations)
            case .failure(let error):
                print("❌ Failed to generate recommendations: \(error)")
                self?.generateFallbackRecommendations(for: user)
            }
        }
    }
    
    private func generateFallbackRecommendations(for user: User) {
        guard let userId = user.id else { return }
        
        print("🔄 Generating fallback recommendations")
        
        var recommendations: [UserRecommendation] = []
        
        // Skill-based teammate recommendations
        for skill in user.skills.prefix(2) {
            recommendations.append(UserRecommendation(
                type: .teammate,
                title: "Find \(skill) Collaborators",
                description: "Connect with other \(skill) experts for your projects",
                score: 0.85,
                reasons: ["Shared expertise", "Collaboration potential"]
            ))
        }
        
        // Interest-based project recommendations
        for interest in user.interests.prefix(2) {
            recommendations.append(UserRecommendation(
                type: .project,
                title: "\(interest) Projects",
                description: "Join exciting \(interest) projects that match your interests",
                score: 0.80,
                reasons: ["Matches interests", "Skill building"]
            ))
        }
        
        saveRecommendations(userId: userId, recommendations: recommendations)
    }
    
    private func saveRecommendations(userId: String, recommendations: [UserRecommendation]) {
        print("💾 Saving recommendations to recommendation collection")
        
        let data: [String: Any] = [
            "user_id": userId,
            "recommendations": recommendations.map { rec in
                [
                    "type": rec.type.rawValue,
                    "title": rec.title,
                    "description": rec.description,
                    "score": rec.score,
                    "reasons": rec.reasons
                ]
            },
            "generated_at": FieldValue.serverTimestamp(),
            "expires_at": Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        ]
        
        db.collection("recommendation").document(userId).setData(data, merge: true) { [weak self] error in
            if let error = error {
                print("❌ Failed to save recommendations: \(error)")
            } else {
                print("✅ Recommendations saved to recommendation collection")
                self?.loadRecommendations(for: userId)
            }
        }
    }
    
    func loadRecommendations(for userId: String) {
        print("📖 Loading recommendations from recommendation collection")
        
        db.collection("recommendation").document(userId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let recommendationsData = data["recommendations"] as? [[String: Any]] else {
                print("📭 No recommendations found")
                return
            }
            
            let recommendations = recommendationsData.compactMap { recData -> UserRecommendation? in
                guard let type = recData["type"] as? String,
                      let title = recData["title"] as? String,
                      let description = recData["description"] as? String,
                      let score = recData["score"] as? Double,
                      let reasons = recData["reasons"] as? [String] else {
                    return nil
                }
                
                return UserRecommendation(
                    type: RecommendationType(rawValue: type) ?? .teammate,
                    title: title,
                    description: description,
                    score: score,
                    reasons: reasons
                )
            }
            
            DispatchQueue.main.async {
                self?.recommendations = recommendations
            }
            
            print("✅ Loaded \(recommendations.count) recommendations")
        }
    }
    
    // MARK: - Helper Functions
    func retryConnection() {
        DispatchQueue.main.async {
            self.connectionError = false
            self.isLoading = true
        }
        checkAuthStatus()
    }
    
    func skipLoading() {
        DispatchQueue.main.async {
            self.isLoading = false
            self.connectionError = false
        }
    }
}
