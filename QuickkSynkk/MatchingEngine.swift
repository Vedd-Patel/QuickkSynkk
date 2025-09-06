//
//  MatchingEngine.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//

import Foundation

class MatchingEngine: ObservableObject {
    static let shared = MatchingEngine()
    private init() {}

    // MARK: - User Matching Algorithm
    func findMatches(for currentUser: User, from users: [User]) -> [MatchResult] {
        let otherUsers = users.filter { $0.id != currentUser.id }

        return otherUsers.map { user in
            let matchScore = calculateMatchScore(currentUser: currentUser, targetUser: user)
            let reasons = generateCompatibilityReasons(currentUser: currentUser, targetUser: user)
            let sharedSkills = Array(Set(currentUser.skills).intersection(Set(user.skills)))
            let complementarySkills = findComplementarySkills(currentUser: currentUser, targetUser: user)
            let availabilityOverlap = calculateAvailabilityOverlap(user1: currentUser, user2: user)

            return MatchResult(
                user: user,
                matchScore: matchScore,
                compatibilityReasons: reasons,
                sharedSkills: sharedSkills,
                complementarySkills: complementarySkills,
                availabilityOverlap: availabilityOverlap
            )
        }
        .sorted { $0.matchScore > $1.matchScore }
    }

    // MARK: - Match Score Calculation
    private func calculateMatchScore(currentUser: User, targetUser: User) -> Double {
        let skillsScore = calculateSkillsCompatibility(currentUser: currentUser, targetUser: targetUser)
        let interestsScore = calculateInterestsAlignment(currentUser: currentUser, targetUser: targetUser)
        let experienceScore = calculateExperienceCompatibility(currentUser: currentUser, targetUser: targetUser)
        let availabilityScore = calculateAvailabilityOverlap(user1: currentUser, user2: targetUser)

        // Weights: skills 40%, interests 25%, experience 15%, availability 20%
        let total = (skillsScore * 0.4)
                  + (interestsScore * 0.25)
                  + (experienceScore * 0.15)
                  + (availabilityScore * 0.2)
        return min(total, 1.0)
    }

    private func calculateSkillsCompatibility(currentUser: User, targetUser: User) -> Double {
        let currentSkills = Set(currentUser.skills)
        let targetSkills = Set(targetUser.skills)
        let sharedCount = currentSkills.intersection(targetSkills).count
        let complementaryCount = findComplementarySkills(currentUser: currentUser, targetUser: targetUser).count
        let total = max(currentSkills.count, targetSkills.count)
        guard total > 0 else { return 0 }

        // Shared weight 60%, complementary 40%
        let sharedScore = Double(sharedCount) / Double(total)
        let complementaryScore = Double(complementaryCount) / Double(total)
        return (sharedScore * 0.6) + (complementaryScore * 0.4)
    }

    private func calculateInterestsAlignment(currentUser: User, targetUser: User) -> Double {
        let shared = Set(currentUser.interests).intersection(Set(targetUser.interests)).count
        let total = max(currentUser.interests.count, targetUser.interests.count)
        return total > 0 ? Double(shared) / Double(total) : 0
    }

    private func calculateExperienceCompatibility(currentUser: User, targetUser: User) -> Double {
        let levels: [ExperienceLevel] = [.beginner, .intermediate, .advanced, .expert]
        guard let idx1 = levels.firstIndex(of: currentUser.experience),
              let idx2 = levels.firstIndex(of: targetUser.experience) else {
            return 0.5
        }
        let diff = abs(idx1 - idx2)
        switch diff {
        case 0: return 1.0
        case 1: return 0.8
        case 2: return 0.6
        case 3: return 0.4
        default: return 0.2
        }
    }

    func calculateAvailabilityOverlap(user1: User, user2: User) -> Double {
        var slots1 = [String: Bool]()
        var slots2 = [String: Bool]()

        func fill(_ user: User, into dict: inout [String: Bool]) {
            for slot in user.availability {
                for hour in slot.startHour..<slot.endHour {
                    dict["\(slot.dayOfWeek)-\(hour)"] = slot.isAvailable
                }
            }
        }
        fill(user1, into: &slots1); fill(user2, into: &slots2)

        let allKeys = Set(slots1.keys).union(slots2.keys)
        guard !allKeys.isEmpty else { return 0 }
        let overlap = allKeys.filter { slots1[$0] == true && slots2[$0] == true }.count
        return Double(overlap) / Double(allKeys.count)
    }

    // MARK: - Helpers
    private func findComplementarySkills(currentUser: User, targetUser: User) -> [String] {
        let map: [String: [String]] = [
            "Frontend Development": ["Backend Development", "UI/UX Design"],
            "Backend Development": ["Frontend Development", "DevOps"],
            "UI/UX Design": ["Frontend Development", "User Research"],
            "iOS Development": ["Backend Development", "UI/UX Design"],
            "Data Science": ["Machine Learning", "Statistics"],
            "Machine Learning": ["Data Science", "Python"],
            "Project Management": ["Communication", "Leadership"]
        ]
        let cur = Set(currentUser.skills), tar = Set(targetUser.skills)
        return map.flatMap { skill, comps in
            cur.contains(skill) ? comps.filter(tar.contains) : []
        }
    }

    private func generateCompatibilityReasons(currentUser: User, targetUser: User) -> [String] {
        var reasons = [String]()
        let shared = Set(currentUser.skills).intersection(Set(targetUser.skills))
        let interests = Set(currentUser.interests).intersection(Set(targetUser.interests))
        let complement = findComplementarySkills(currentUser: currentUser, targetUser: targetUser)
        let avail = calculateAvailabilityOverlap(user1: currentUser, user2: targetUser)

        if !shared.isEmpty { reasons.append("Shared skills: \(shared.joined(separator: ", "))") }
        if !interests.isEmpty { reasons.append("Common interests: \(interests.joined(separator: ", "))") }
        if !complement.isEmpty { reasons.append("Complementary skills: \(complement.joined(separator: ", "))") }
        if currentUser.experience == targetUser.experience {
            reasons.append("Same experience: \(currentUser.experience.rawValue)")
        }
        if avail > 0.5 {
            reasons.append("Good schedule compatibility")
        }
        return reasons
    }
}
