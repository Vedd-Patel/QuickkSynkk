//
//  SmartRecommendationEngine.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//


import Foundation

class SmartRecommendationEngine {
    
    func generateRecommendations(
        userSkills: [String],
        userInterests: [String],
        userExperience: String,
        userRole: String,
        completion: @escaping (Result<[UserRecommendation], Error>) -> Void
    ) {
        
        print("🧠 Generating smart recommendations...")
        print("   Skills: \(userSkills)")
        print("   Interests: \(userInterests)")
        print("   Experience: \(userExperience)")
        print("   Role: \(userRole)")
        
        // Simulate processing time
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let recommendations = self.buildIntelligentRecommendations(
                skills: userSkills,
                interests: userInterests,
                experience: userExperience,
                role: userRole
            )
            
            DispatchQueue.main.async {
                completion(.success(recommendations))
            }
        }
    }
    
    private func buildIntelligentRecommendations(
        skills: [String],
        interests: [String],
        experience: String,
        role: String
    ) -> [UserRecommendation] {
        
        var recommendations: [UserRecommendation] = []
        
        // 1. Teammate Recommendations based on complementary skills
        recommendations.append(contentsOf: generateTeammateRecommendations(
            userSkills: skills,
            userRole: role,
            experience: experience
        ))
        
        // 2. Skill Development Recommendations
        recommendations.append(contentsOf: generateSkillRecommendations(
            currentSkills: skills,
            experience: experience,
            role: role
        ))
        
        // 3. Project Recommendations based on interests
        recommendations.append(contentsOf: generateRecommendationsType(
            interests: interests,
            skills: skills,
            experience: experience
        ))
        
        // 4. Event Recommendations
        recommendations.append(contentsOf: generateEventRecommendations(
            interests: interests,
            skills: skills
        ))
        
        // 5. Learning Path Recommendations
        recommendations.append(contentsOf: generateLearningRecommendations(
            skills: skills,
            experience: experience,
            role: role
        ))
        
        // Sort by score and return top recommendations
        let sortedRecommendations = recommendations.sorted { $0.score > $1.score }
        return Array(sortedRecommendations.prefix(8))
    }
    
    private func generateTeammateRecommendations(userSkills: [String], userRole: String, experience: String) -> [UserRecommendation] {
        
        let complementarySkillsMap: [String: [String]] = [
            "Swift": ["UI/UX Design", "Backend Development", "Product Management", "Quality Assurance"],
            "UI/UX Design": ["Frontend Development", "Swift", "React", "User Research"],
            "Backend Development": ["Frontend Development", "DevOps", "Database Design", "API Design"],
            "Python": ["Data Science", "Machine Learning", "Web Development", "DevOps"],
            "React": ["Backend Development", "UI/UX Design", "Mobile Development", "Testing"],
            "JavaScript": ["Backend Development", "UI/UX Design", "Testing", "DevOps"],
            "Machine Learning": ["Data Science", "Python", "Statistics", "Research"],
            "Data Science": ["Machine Learning", "Statistics", "Business Analysis", "Visualization"],
            "Project Management": ["Technical Writing", "Business Analysis", "Marketing", "Strategy"],
            "DevOps": ["Backend Development", "Cloud Computing", "Security", "Monitoring"],
            "Mobile Development": ["UI/UX Design", "Backend Development", "Testing", "Analytics"]
        ]
        
        var recommendations: [UserRecommendation] = []
        
        for skill in userSkills.prefix(3) { // Limit to top 3 skills
            if let complementarySkills = complementarySkillsMap[skill] {
                for compSkill in complementarySkills.prefix(2) {
                    let score = calculateTeammateCompatibilityScore(
                        userSkill: skill,
                        complementarySkill: compSkill,
                        experience: experience
                    )
                    
                    recommendations.append(UserRecommendation(
                        type: .teammate,
                        title: "Partner with \(compSkill) Experts",
                        description: "Find teammates skilled in \(compSkill) to complement your \(skill) expertise and create well-rounded projects",
                        score: score,
                        reasons: [
                            "Complementary to your \(skill) skills",
                            "High collaboration potential",
                            "Balanced team composition"
                        ]
                    ))
                }
            }
        }
        
        return recommendations
    }
    
    private func generateSkillRecommendations(currentSkills: [String], experience: String, role: String) -> [UserRecommendation] {
        
        let skillProgression: [String: [String]] = [
            "Swift": ["SwiftUI", "Combine", "Core Data", "ARKit", "CloudKit"],
            "UI/UX Design": ["Figma Advanced", "Design Systems", "User Research", "Prototyping", "Accessibility"],
            "Python": ["Django", "FastAPI", "TensorFlow", "Docker", "AWS"],
            "React": ["Next.js", "TypeScript", "React Native", "GraphQL", "Redux"],
            "JavaScript": ["Node.js", "TypeScript", "Vue.js", "Express", "MongoDB"],
            "Machine Learning": ["Deep Learning", "MLOps", "Computer Vision", "NLP", "PyTorch"],
            "Backend Development": ["Microservices", "GraphQL", "Docker", "Kubernetes", "API Design"],
            "Frontend Development": ["TypeScript", "Progressive Web Apps", "Testing", "Performance Optimization"],
            "Mobile Development": ["React Native", "Flutter", "Kotlin", "iOS", "Cross-platform"]
        ]
        
        var recommendations: [UserRecommendation] = []
        
        for skill in currentSkills.prefix(2) {
            if let nextSkills = skillProgression[skill] {
                for nextSkill in nextSkills.prefix(2) {
                    let score = calculateSkillLearningScore(
                        currentSkill: skill,
                        nextSkill: nextSkill,
                        experience: experience
                    )
                    
                    recommendations.append(UserRecommendation(
                        type: .skill,
                        title: "Master \(nextSkill)",
                        description: "Take your \(skill) expertise to the next level by learning \(nextSkill) - a natural progression for \(experience.lowercased()) developers",
                        score: score,
                        reasons: [
                            "Natural progression from \(skill)",
                            "High industry demand",
                            "Career advancement opportunity"
                        ]
                    ))
                }
            }
        }
        
        return recommendations
    }
    
    private func generateRecommendationsType(interests: [String], skills: [String], experience: String) -> [UserRecommendation] {
        
        let projectIdeas: [String: [(String, String, Double)]] = [
            "Hackathon": [
                ("AI-Powered Sustainability Challenge", "24-hour hackathon focused on environmental solutions using AI and machine learning", 0.90),
                ("Mobile Health Innovation Contest", "Develop mobile applications that improve healthcare accessibility", 0.85),
                ("Fintech Disruption Hackathon", "Create innovative financial technology solutions", 0.80)
            ],
            "Mobile Development": [
                ("Cross-Platform Social App", "Build a social networking application using modern mobile frameworks", 0.88),
                ("AR Shopping Experience", "Create an augmented reality application for retail", 0.85),
                ("Fitness Tracking Ecosystem", "Develop a comprehensive health and fitness mobile platform", 0.82)
            ],
            "Web Development": [
                ("Developer Community Platform", "Build a collaborative platform for developers to share projects and connect", 0.90),
                ("Real-time Collaboration Suite", "Create a comprehensive team productivity and collaboration tool", 0.87),
                ("E-commerce Analytics Dashboard", "Develop advanced analytics and business intelligence platform", 0.84)
            ],
            "AI/ML": [
                ("Computer Vision for Accessibility", "AI system to help visually impaired users navigate", 0.92),
                ("Natural Language Processing Tool", "Smart text analysis and generation platform", 0.89),
                ("Predictive Analytics Platform", "Business intelligence tool with machine learning", 0.86)
            ],
            "Design": [
                ("Design System Framework", "Create comprehensive design system for developers", 0.88),
                ("User Experience Research Tool", "Platform for conducting and analyzing UX research", 0.85),
                ("Accessibility Design Checker", "Tool to ensure digital accessibility compliance", 0.83)
            ]
        ]
        
        var recommendations: [UserRecommendation] = []
        
        for interest in interests.prefix(2) {
            if let projects = projectIdeas[interest] {
                for (title, description, baseScore) in projects.prefix(1) {
                    let score = adjustScoreForExperience(baseScore: baseScore, experience: experience)
                    
                    recommendations.append(UserRecommendation(
                        type: .project,
                        title: title,
                        description: description,
                        score: score,
                        reasons: [
                            "Aligns with your \(interest) interests",
                            "Matches your skill level",
                            "Great for portfolio building"
                        ]
                    ))
                }
            }
        }
        
        return recommendations
    }
    
    private func generateEventRecommendations(interests: [String], skills: [String]) -> [UserRecommendation] {
        
        let eventRecommendations: [(String, String, [String])] = [
            ("iOS Developer Meetup", "Connect with local iOS developers and learn about latest Swift developments", ["Swift", "Mobile Development"]),
            ("AI/ML Workshop Series", "Hands-on workshops covering machine learning and artificial intelligence", ["Machine Learning", "Python", "AI/ML"]),
            ("UX Design Conference", "Learn from industry leaders about user experience and design thinking", ["UI/UX Design", "Design"]),
            ("Startup Pitch Competition", "Present your ideas and connect with entrepreneurs and investors", ["Business", "Entrepreneurship"]),
            ("Open Source Contribution Day", "Learn how to contribute to open source projects and collaborate with global developers", ["Programming", "Collaboration"]),
            ("Web Development Bootcamp", "Intensive workshop on modern web development techniques", ["Web Development", "JavaScript", "React"])
        ]
        
        var recommendations: [UserRecommendation] = []
        
        for (title, description, relevantSkills) in eventRecommendations {
            let relevanceScore = calculateEventRelevance(
                userSkills: skills,
                userInterests: interests,
                eventSkills: relevantSkills
            )
            
            if relevanceScore > 0.6 {
                recommendations.append(UserRecommendation(
                    type: .event,
                    title: title,
                    description: description,
                    score: relevanceScore,
                    reasons: [
                        "Relevant to your skills",
                        "Great networking opportunity",
                        "Learn from industry experts"
                    ]
                ))
            }
        }
        
        return recommendations
    }
    
    private func generateLearningRecommendations(skills: [String], experience: String, role: String) -> [UserRecommendation] {
        
        let learningPaths: [String: (String, String, Double)] = [
            "Swift": ("iOS Development Mastery", "Comprehensive path from beginner to advanced iOS development", 0.90),
            "Python": ("Full-Stack Python Development", "Master backend development, data science, and automation", 0.88),
            "React": ("Modern Frontend Engineering", "Advanced React patterns, performance optimization, and ecosystem", 0.86),
            "UI/UX Design": ("User-Centered Design Systems", "Learn design thinking, research methods, and system design", 0.89),
            "Machine Learning": ("AI/ML Engineering Track", "From fundamentals to production ML systems", 0.92),
            "Backend Development": ("Scalable Systems Architecture", "Design and build high-performance backend systems", 0.87),
            "DevOps": ("Cloud Infrastructure Mastery", "Container orchestration, CI/CD, and cloud platforms", 0.85)
        ]
        
        var recommendations: [UserRecommendation] = []
        
        for skill in skills.prefix(2) {
            if let (title, description, baseScore) = learningPaths[skill] {
                let score = adjustScoreForExperience(baseScore: baseScore, experience: experience)
                
                recommendations.append(UserRecommendation(
                    type: .learning,
                    title: title,
                    description: description,
                    score: score,
                    reasons: [
                        "Structured learning path",
                        "Industry-relevant curriculum",
                        "Advance your \(skill) expertise"
                    ]
                ))
            }
        }
        
        return recommendations
    }
    
    // MARK: - Score Calculation Helpers
    
    private func calculateTeammateCompatibilityScore(userSkill: String, complementarySkill: String, experience: String) -> Double {
        let baseCompatibility: [String: [String: Double]] = [
            "Swift": ["UI/UX Design": 0.95, "Backend Development": 0.90, "Product Management": 0.85],
            "UI/UX Design": ["Frontend Development": 0.93, "User Research": 0.90, "Product Management": 0.88],
            "Backend Development": ["Frontend Development": 0.92, "DevOps": 0.89, "Database Design": 0.87],
            "Machine Learning": ["Data Science": 0.94, "Python": 0.91, "Statistics": 0.88],
            "Python": ["Data Science": 0.90, "Machine Learning": 0.88, "Backend Development": 0.85]
        ]
        
        let baseScore = baseCompatibility[userSkill]?[complementarySkill] ?? 0.80
        
        // Adjust for experience level
        let experienceMultiplier: Double = {
            switch experience {
            case "Beginner": return 0.95
            case "Intermediate": return 1.0
            case "Advanced": return 1.05
            case "Expert": return 1.1
            default: return 1.0
            }
        }()
        
        return min(baseScore * experienceMultiplier, 1.0)
    }
    
    private func calculateSkillLearningScore(currentSkill: String, nextSkill: String, experience: String) -> Double {
        let baseScore = 0.85
        
        let experienceBonus: Double = {
            switch experience {
            case "Beginner": return 0.95 // Encourage learning
            case "Intermediate": return 0.90
            case "Advanced": return 0.85
            case "Expert": return 0.80 // May already know advanced topics
            default: return 0.85
            }
        }()
        
        return baseScore * experienceBonus
    }
    
    private func calculateEventRelevance(userSkills: [String], userInterests: [String], eventSkills: [String]) -> Double {
        let skillMatches = userSkills.filter { eventSkills.contains($0) }.count
        let maxSkillMatches = min(userSkills.count, eventSkills.count)
        
        if maxSkillMatches == 0 {
            return 0.6 // Base score if no direct skill matches
        }
        
        let skillScore = Double(skillMatches) / Double(maxSkillMatches)
        return 0.6 + (skillScore * 0.4) // Scale between 0.6 and 1.0
    }
    
    private func adjustScoreForExperience(baseScore: Double, experience: String) -> Double {
        let experienceAdjustment: Double = {
            switch experience {
            case "Beginner": return 1.1 // Boost learning recommendations
            case "Intermediate": return 1.05
            case "Advanced": return 1.0
            case "Expert": return 0.95
            default: return 1.0
            }
        }()
        
        return min(baseScore * experienceAdjustment, 1.0)
    }
}
