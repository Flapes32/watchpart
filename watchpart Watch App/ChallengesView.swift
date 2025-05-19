//
//  ChallengesView.swift
//  watchpart Watch App
//
//  Created by Apple on 19.05.2025.
//

import SwiftUI

// Challenge model
struct BoxingChallenge: Identifiable {
    let id = UUID()
    let sender: String
    let type: ChallengeType
    let timestamp: Date
    var status: ChallengeStatus
    var userReaction: String?
    var targetValue: Int
    var currentValue: Int = 0
    var expiresAt: Date?
    
    enum ChallengeType: String, CaseIterable {
        case rounds = "Rounds Challenge"
        case heartRate = "Heart Rate Challenge"
        case calories = "Calories Challenge"
        case combo = "Combo Challenge"
        case speedBag = "Speed Bag Challenge"
        case endurance = "Endurance Challenge"
    }
    
    enum ChallengeStatus: String {
        case pending = "Pending"
        case accepted = "Accepted"
        case completed = "Completed"
        case declined = "Declined"
    }
}

struct ChallengesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var challenges: [BoxingChallenge] = []
    @State private var showReactionPicker: Bool = false
    @State private var selectedChallengeId: UUID?
    @State private var selectedTab = 0
    
    // Quick reactions
    let quickReactions = ["👍", "🔥", "💪", "👊", "🥊", "🏆"]
    
    // Filtered challenges
    private var pendingChallenges: [BoxingChallenge] {
        challenges.filter { $0.status == .pending }
    }
    
    private var activeChallenges: [BoxingChallenge] {
        challenges.filter { $0.status == .accepted }
    }
    
    private var completedChallenges: [BoxingChallenge] {
        challenges.filter { $0.status == .completed }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Spacer()
                
                Text("Challenges")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // Add new challenge
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.1))
            
            // Tab View for challenges and reactions
            TabView(selection: $selectedTab) {
                // First Tab - Challenges
                if challenges.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                            .padding(.top, 40)
                        
                        Text("No challenges yet")
                            .font(.headline)
                        
                        Text("Your boxing challenges will appear here")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            // Add sample challenges for demo
                            loadSampleChallenges()
                        }) {
                            Text("Show Demo Challenges")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(0)
                } else {
                    // Challenges list
                    VStack {
                        // Section title
                        HStack {
                            Text("New Challenges")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Text("\(pendingChallenges.count)")
                                .font(.system(size: 12))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.3))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(pendingChallenges) { challenge in
                                    ChallengeCard(
                                        challenge: challenge,
                                        onAccept: {
                                            acceptChallenge(challenge.id)
                                        },
                                        onDecline: {
                                            declineChallenge(challenge.id)
                                        },
                                        onReact: {
                                            selectedChallengeId = challenge.id
                                            showReactionPicker = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // Active challenges section
                            if !activeChallenges.isEmpty {
                                HStack {
                                    Text("Active Challenges")
                                        .font(.system(size: 14, weight: .semibold))
                                    Spacer()
                                    Text("\(activeChallenges.count)")
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.3))
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                                
                                VStack(spacing: 10) {
                                    ForEach(activeChallenges) { challenge in
                                        ChallengeCard(
                                            challenge: challenge,
                                            onAccept: {
                                                acceptChallenge(challenge.id)
                                            },
                                            onDecline: {
                                                declineChallenge(challenge.id)
                                            },
                                            onReact: {
                                                selectedChallengeId = challenge.id
                                                showReactionPicker = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .tag(0)
                    
                    // Second Tab - Reactions and History
                    VStack {
                        // Section title
                        HStack {
                            Text("Completed Challenges")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Text("\(completedChallenges.count)")
                                .font(.system(size: 12))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.3))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        if completedChallenges.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                    .padding(.top, 40)
                                
                                Text("No completed challenges yet")
                                    .font(.headline)
                                
                                Text("Completed challenges will appear here")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                VStack(spacing: 10) {
                                    ForEach(completedChallenges) { challenge in
                                        ChallengeCard(
                                            challenge: challenge,
                                            onAccept: {
                                                acceptChallenge(challenge.id)
                                            },
                                            onDecline: {
                                                declineChallenge(challenge.id)
                                            },
                                            onReact: {
                                                selectedChallengeId = challenge.id
                                                showReactionPicker = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .tag(1)
                }
            }
            #if os(watchOS)
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle())
            #endif
            
            // Reaction picker
            if showReactionPicker {
                VStack(spacing: 10) {
                    Text("Send Reaction")
                        .font(.caption)
                    
                    HStack(spacing: 12) {
                        ForEach(quickReactions, id: \.self) { emoji in
                            Button(action: {
                                if let id = selectedChallengeId {
                                    sendReaction(to: id, reaction: emoji)
                                }
                                showReactionPicker = false
                            }) {
                                Text(emoji)
                                    .font(.system(size: 24))
                            }
                        }
                    }
                    
                    Button("Cancel") {
                        showReactionPicker = false
                    }
                    .font(.caption)
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.black.opacity(0.1))
            }
        }
        .onAppear {
            // Load sample challenges when view appears if list is empty
            if challenges.isEmpty {
                loadSampleChallenges()
            }
        }
    }
    
    // MARK: - Helper methods
    
    private func acceptChallenge(_ id: UUID) {
        if let index = challenges.firstIndex(where: { $0.id == id }) {
            challenges[index].status = .accepted
        }
    }
    
    private func declineChallenge(_ id: UUID) {
        if let index = challenges.firstIndex(where: { $0.id == id }) {
            challenges[index].status = .declined
        }
    }
    
    private func sendReaction(to id: UUID, reaction: String) {
        if let index = challenges.firstIndex(where: { $0.id == id }) {
            challenges[index].userReaction = reaction
        }
    }
    
    private func loadSampleChallenges() {
        let sampleChallenges: [BoxingChallenge] = [
            // Pending challenges
            BoxingChallenge(
                sender: "Alex",
                type: .rounds,
                timestamp: Date().addingTimeInterval(-3600),
                status: .pending,
                userReaction: nil,
                targetValue: 5,
                currentValue: 0,
                expiresAt: Date().addingTimeInterval(86400)
            ),
            BoxingChallenge(
                sender: "Jamie",
                type: .combo,
                timestamp: Date().addingTimeInterval(-2800),
                status: .pending,
                userReaction: nil,
                targetValue: 50,
                currentValue: 0,
                expiresAt: Date().addingTimeInterval(72000)
            ),
            BoxingChallenge(
                sender: "Carlos",
                type: .speedBag,
                timestamp: Date().addingTimeInterval(-1200),
                status: .pending,
                userReaction: nil,
                targetValue: 120,
                currentValue: 0,
                expiresAt: Date().addingTimeInterval(43200)
            ),
            
            // Active challenges
            BoxingChallenge(
                sender: "Mike",
                type: .heartRate,
                timestamp: Date().addingTimeInterval(-7200),
                status: .accepted,
                userReaction: nil,
                targetValue: 160,
                currentValue: 145,
                expiresAt: Date().addingTimeInterval(43200)
            ),
            BoxingChallenge(
                sender: "Sophia",
                type: .endurance,
                timestamp: Date().addingTimeInterval(-5400),
                status: .accepted,
                userReaction: nil,
                targetValue: 20,
                currentValue: 8,
                expiresAt: Date().addingTimeInterval(36000)
            ),
            BoxingChallenge(
                sender: "Coach David",
                type: .rounds,
                timestamp: Date().addingTimeInterval(-8600),
                status: .accepted,
                userReaction: nil,
                targetValue: 8,
                currentValue: 3,
                expiresAt: Date().addingTimeInterval(28800)
            ),
            
            // Completed challenges
            BoxingChallenge(
                sender: "Sarah",
                type: .calories,
                timestamp: Date().addingTimeInterval(-10800),
                status: .completed,
                userReaction: "🔥",
                targetValue: 300,
                currentValue: 320,
                expiresAt: Date().addingTimeInterval(-3600)
            ),
            BoxingChallenge(
                sender: "Training Group",
                type: .combo,
                timestamp: Date().addingTimeInterval(-86400),
                status: .completed,
                userReaction: "👊",
                targetValue: 30,
                currentValue: 42,
                expiresAt: Date().addingTimeInterval(-43200)
            ),
            BoxingChallenge(
                sender: "Gym Partner",
                type: .speedBag,
                timestamp: Date().addingTimeInterval(-172800),
                status: .completed,
                userReaction: "🏆",
                targetValue: 90,
                currentValue: 95,
                expiresAt: Date().addingTimeInterval(-86400)
            ),
            BoxingChallenge(
                sender: "Weekly Challenge",
                type: .endurance,
                timestamp: Date().addingTimeInterval(-259200),
                status: .completed,
                userReaction: "💪",
                targetValue: 15,
                currentValue: 15,
                expiresAt: Date().addingTimeInterval(-172800)
            ),
            BoxingChallenge(
                sender: "Lisa",
                type: .endurance,
                timestamp: Date().addingTimeInterval(-21600),
                status: .accepted,
                userReaction: "👊",
                targetValue: 45,
                currentValue: 20,
                expiresAt: Date().addingTimeInterval(43200)
            )
        ]
        
        challenges = sampleChallenges
    }
}

// MARK: - Challenge Card View

struct ChallengeCard: View {
    let challenge: BoxingChallenge
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onReact: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: challengeIcon)
                    .foregroundColor(challengeColor)
                
                Text(challenge.type.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text(challenge.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
            }
            
            Divider()
            
            // Content
            HStack {
                Text("From: \(challenge.sender)")
                    .font(.subheadline)
                
                Spacer()
                
                Text(formatDate(challenge.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Challenge description
            Text(challengeDescription)
                .font(.caption)
                .padding(.top, 4)
            
            // Reaction if any
            if let reaction = challenge.userReaction {
                HStack {
                    Spacer()
                    
                    Text(reaction)
                        .font(.title2)
                        .padding(6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
            
            // Action buttons
            if challenge.status == .pending {
                HStack {
                    Button(action: onAccept) {
                        Text("Accept")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    Button(action: onDecline) {
                        Text("Decline")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    Button(action: onReact) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 16))
                    }
                }
                .padding(.top, 8)
            } else {
                HStack {
                    Spacer()
                    
                    Button(action: onReact) {
                        HStack {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 16))
                            
                            Text("React")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper properties
    
    private var challengeIcon: String {
        switch challenge.type {
        case .rounds:
            return "timer"
        case .heartRate:
            return "heart.fill"
        case .calories:
            return "flame.fill"
        case .combo:
            return "figure.boxing"
        case .speedBag:
            return "speedometer"
        case .endurance:
            return "figure.run"
        }
    }
    
    private var challengeColor: Color {
        switch challenge.type {
        case .rounds:
            return .blue
        case .heartRate:
            return .red
        case .calories:
            return .orange
        case .combo:
            return .purple
        case .speedBag:
            return .green
        case .endurance:
            return .indigo
        }
    }
    
    private var statusColor: Color {
        switch challenge.status {
        case .pending:
            return .yellow
        case .accepted:
            return .blue
        case .completed:
            return .green
        case .declined:
            return .red
        }
    }
    
    private var challengeDescription: String {
        switch challenge.type {
        case .rounds:
            return "Complete \(challenge.targetValue) rounds of 3 minutes each with 1 minute rest"
        case .heartRate:
            return "Maintain your heart rate at \(challenge.targetValue) BPM for 20 minutes"
        case .calories:
            return "Burn \(challenge.targetValue) calories during your boxing workout"
        case .combo:
            return "Perform \(challenge.targetValue) jab-cross-hook combinations"
        case .speedBag:
            return "Hit the speed bag \(challenge.targetValue) times without stopping"
        case .endurance:
            return "Complete \(challenge.targetValue) minutes of non-stop shadow boxing"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChallengesView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengesView()
    }
}
