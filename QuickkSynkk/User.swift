//
//  User.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//
import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - User Model
struct User: Codable, Identifiable {
    var id: String?
    var name: String
    var email: String
    var bio: String
    var skills: [String]
    var interests: [String]
    var availability: [AvailabilitySlot]
    var location: String
    var experience: ExperienceLevel
    var role: UserRole
    var joinedDate: Date
    var completedProjects: Int
    var rating: Double
    
    init(id: String? = nil, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
        self.bio = ""
        self.skills = []
        self.interests = []
        self.availability = []
        self.location = ""
        self.experience = .beginner
        self.role = .developer
        self.joinedDate = Date()
        self.completedProjects = 0
        self.rating = 5.0
    }
}

// MARK: - Experience Level
enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}

// MARK: - User Role
enum UserRole: String, Codable, CaseIterable {
    case developer = "Developer"
    case designer = "Designer"
    case manager = "Manager"
    case marketing = "Marketing"
    case analyst = "Analyst"
}

// MARK: - Availability Slot
struct AvailabilitySlot: Codable, Identifiable {
    let id = UUID()
    var dayOfWeek: Int
    var startHour: Int
    var endHour: Int
    var isAvailable: Bool
    
    var dayName: String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[dayOfWeek]
    }
}

// MARK: - Team Model
struct Team: Codable, Identifiable {
    var id: String?
    var name: String
    var description: String
    var projectType: ProjectType
    var requiredSkills: [String]
    var maxMembers: Int
    var currentMembers: [TeamMember]
    var createdBy: String
    var tags: [String]
    var difficulty: DifficultyLevel
    var estimatedHours: Int
    var status: TeamStatus
    var createdAt: Date?
    
    init() {
        self.name = ""
        self.description = ""
        self.projectType = .hackathon
        self.requiredSkills = []
        self.maxMembers = 5
        self.currentMembers = []
        self.createdBy = ""
        self.tags = []
        self.difficulty = .intermediate
        self.estimatedHours = 20
        self.status = .recruiting
        self.createdAt = nil
    }
}

// MARK: - Project Type
enum ProjectType: String, Codable, CaseIterable {
    case hackathon = "Hackathon"
    case longTerm = "Long-term Project"
    case contest = "Contest"
    case openSource = "Open Source"
    case startup = "Startup"
    case research = "Research"
}

// MARK: - Team Member
struct TeamMember: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let role: String
    let joinedAt: Date
    let skills: [String]
}

// MARK: - Difficulty Level
enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}

// MARK: - Team Status (FIXED - Added missing cases)
enum TeamStatus: String, Codable, CaseIterable {
    case recruiting = "Recruiting"
    case active = "Active"
    case completed = "Completed"
    case onHold = "On Hold"
    case full = "Full"           // ← ADDED
    case paused = "Paused"       // ← ADDED
}

// MARK: - Event Model
struct Event: Codable, Identifiable {
    var id: String?
    var title: String
    var description: String
    var type: EventType
    var startDate: Date
    var endDate: Date
    var location: String
    var maxParticipants: Int
    var currentParticipants: [String]
    var teams: [String]
    var tags: [String]
    var createdBy: String
    var createdAt: Date?
    
    enum EventType: String, Codable, CaseIterable {
        case hackathon = "Hackathon"
        case workshop = "Workshop"
        case meetup = "Meetup"
        case competition = "Competition"
        case designathon = "Designathon"
    }
    
    init() {
        self.title = ""
        self.description = ""
        self.type = .hackathon
        self.startDate = Date()
        self.endDate = Date()
        self.location = ""
        self.maxParticipants = 50
        self.currentParticipants = []
        self.teams = []
        self.tags = []
        self.createdBy = ""
        self.createdAt = nil
    }
}

// MARK: - Collaboration Request (FIXED)
struct CollaborationRequest: Codable, Identifiable {
    var id: String?
    var fromUserId: String
    var toUserId: String
    var message: String
    var status: RequestStatus
    var createdAt: Date
    var requestType: RequestType
    
    enum RequestStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
    }
    
    enum RequestType: String, Codable, CaseIterable {
        case directCollaboration = "direct_collaboration"
        case teamInvitation = "team_invitation"
        case projectInvitation = "project_invitation"
        case teamJoin = "team_join"     // ← ADDED
    }
    
    // ADDED INITIALIZER
    init(fromUserId: String, toUserId: String, message: String, status: RequestStatus, createdAt: Date, requestType: RequestType) {
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.message = message
        self.status = status
        self.createdAt = createdAt
        self.requestType = requestType
    }
}

// MARK: - User Recommendation
struct UserRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let score: Double
    let reasons: [String]
}

enum RecommendationType: String, CaseIterable {
    case teammate = "teammate"
    case project = "project"
    case skill = "skill"
    case event = "event"
    case learning = "learning"
    
    var icon: String {
        switch self {
        case .teammate: return "person.2.fill"
        case .project: return "folder.fill"
        case .skill: return "star.fill"
        case .event: return "calendar.badge.plus"
        case .learning: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .teammate: return .filterBlue
        case .project: return .filterGreen
        case .skill: return .filterOrange
        case .event: return .filterPurple
        case .learning: return .filterRed
        }
    }
}

// MARK: - Match Result
struct MatchResult: Identifiable {
    let id = UUID()
    let user: User
    let matchScore: Double
    let compatibilityReasons: [String]
    let sharedSkills: [String]
    let complementarySkills: [String]
    let availabilityOverlap: Double
}

// MARK: - Skill Count
struct SkillCount: Identifiable {
    let id = UUID()
    let skill: String
    let count: Int
}
