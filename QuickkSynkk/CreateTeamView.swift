//
//  CreateTeamView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//


//
//  CreateTeamView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//

import SwiftUI

struct CreateTeamView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared

    @State private var teamName = ""
    @State private var description = ""
    @State private var selectedProjectType: ProjectType = .hackathon
    @State private var maxMembers = 5
    @State private var requiredSkills: [String] = []
    @State private var newSkill = ""
    @State private var isCreating = false

    var isFormValid: Bool {
        !teamName.isEmpty && !description.isEmpty && !requiredSkills.isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Info
                    Group {
                        TextField("Team Name", text: $teamName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Description", text: $description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()

                    // Project Type & Max Members
                    Group {
                        Picker("Project Type", selection: $selectedProjectType) {
                            ForEach(ProjectType.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        Stepper("Max Members: \(maxMembers)", value: $maxMembers, in: 2...20)
                    }
                    .padding()

                    // Skills
                    VStack(spacing: 12) {
                        HStack {
                            TextField("Add skill", text: $newSkill)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Add") {
                                if !newSkill.isEmpty && !requiredSkills.contains(newSkill) {
                                    requiredSkills.append(newSkill)
                                    newSkill = ""
                                }
                            }
                        }
                        if !requiredSkills.isEmpty {
                            FlowLayout(items: requiredSkills, id: \.self) { skill in
                                Text(skill)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()

                    // Create Button
                    Button(action: createTeam) {
                        HStack {
                            if isCreating {
                                ProgressView()
                            }
                            Text(isCreating ? "Creating..." : "Create Team")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isCreating)
                    .padding()
                }
            }
            .navigationTitle("Create Team")
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
    }

    func createTeam() {
        guard let userId = firebaseManager.currentUser?.id else { return }
        isCreating = true

        var team = Team()
        team.name = teamName
        team.description = description
        team.projectType = selectedProjectType
        team.requiredSkills = requiredSkills
        team.maxMembers = maxMembers
        team.createdBy = userId

        firebaseManager.createTeam(team: team) { result in
            DispatchQueue.main.async {
                isCreating = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    print("Failed to create team:", error)
                }
            }
        }
    }
}

// Simple flow layout for tags
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    init(items: Data, id: KeyPath<Data.Element, Data.Element>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > g.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0 // last item
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last {
                            height = 0 // last item
                        }
                        return result
                    }
            }
        }
        .frame(height: -height)
    }
}

struct CreateTeamView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTeamView()
    }
}
