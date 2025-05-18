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
    
    enum ChallengeType: String {
        case rounds = "Rounds Challenge"
        case heartRate = "Heart Rate Challenge"
        case calories = "Calories Challenge"
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
    
    // Quick reactions
    let quickReactions = ["👍", "🔥", "💪", "👊", "🥊", "🏆"]
    
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
            
            // Challenges list
            if challenges.isEmpty {
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
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(challenges) { challenge in
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
                    .padding()
                }
            }
            
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
            BoxingChallenge(
                sender: "Alex",
                type: .rounds,
                timestamp: Date().addingTimeInterval(-3600),
                status: .pending
            ),
            BoxingChallenge(
                sender: "Maria",
                type: .heartRate,
                timestamp: Date().addingTimeInterval(-7200),
                status: .accepted,
                userReaction: "🔥"
            ),
            BoxingChallenge(
                sender: "John",
                type: .calories,
                timestamp: Date().addingTimeInterval(-86400),
                status: .completed,
                userReaction: "💪"
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
            return "Complete 5 rounds of 3 minutes each with 1 minute rest"
        case .heartRate:
            return "Maintain your heart rate in the target zone (120-160 BPM) for 20 minutes"
        case .calories:
            return "Burn 300 calories during your boxing workout"
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
