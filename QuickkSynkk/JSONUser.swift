//
//  JSONUser.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//


import Foundation

struct JSONUser: Codable, Identifiable {
  var id: String
  var name: String
  var email: String
  var bio: String
  var skills: [String]
  var interests: [String]
  var availability: [AvailabilitySlot]
  var location: String
  var experience: String
  var role: String
  var joinedDate: Date
  var completedProjects: Int
  var rating: Double
}
