//
//  ChatView.swift
//  watchpart Watch App
//
//  Created by Apple on 19.05.2025.
//

import SwiftUI

// Message model
struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: String
    let content: String
    let isCurrentUser: Bool
    let timestamp: Date
    
    // For quick reactions
    var reaction: String?
}

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""
    @State private var showEmojiPicker: Bool = false
    @State private var selectedMessageId: UUID?
    
    // Sample users for demo
    let users = ["Alex", "Maria", "John", "Sara"]
    
    // Quick reaction emojis
    let quickReactions = ["👍", "🔥", "💪", "👊", "🥊", "🏆"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal header without back button
            HStack {
                Spacer()
                
                Text("Chat")
                    .font(.system(size: 12, weight: .medium))
                
                Spacer()
            }
            .frame(height: 20)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.1))
            
            // Messages list - more compact
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(messages) { message in
                            MessageBubble(message: message) { reaction in
                                addReaction(to: message.id, reaction: reaction)
                            }
                            .id(message.id)
                            .onTapGesture {
                                if selectedMessageId == message.id {
                                    selectedMessageId = nil
                                    showEmojiPicker = false
                                } else {
                                    selectedMessageId = message.id
                                    showEmojiPicker = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .onChange(of: messages.count) { oldCount, newCount in
                        if let lastMessage = messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Message input
            if showEmojiPicker, let selectedId = selectedMessageId {
                // Emoji reaction picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickReactions, id: \.self) { emoji in
                            Button(action: {
                                addReaction(to: selectedId, reaction: emoji)
                                showEmojiPicker = false
                                selectedMessageId = nil
                            }) {
                                Text(emoji)
                                    .font(.system(size: 20))
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .background(Color.black.opacity(0.05))
            } else {
                // Text input
                HStack(spacing: 4) {
                    Button(action: {
                        // Open emoji picker
                    }) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 20, height: 20)
                    
                    TextField("Msg", text: $newMessage)
                        .font(.system(size: 12))
                        .padding(3)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                        .frame(height: 24)
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 20, height: 20)
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.05))
            }
        }
        .onAppear {
            // Load sample messages
            loadSampleMessages()
        }
    }
    
    // MARK: - Helper methods
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedMessage.isEmpty {
            let message = ChatMessage(
                sender: "You",
                content: trimmedMessage,
                isCurrentUser: true,
                timestamp: Date()
            )
            
            messages.append(message)
            newMessage = ""
            
            // Simulate response after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                simulateResponse()
            }
        }
    }
    
    private func simulateResponse() {
        let randomUser = users.randomElement() ?? "Alex"
        let responses = [
            "Great workout today! 💪",
            "How was your training?",
            "Did you reach your target heart rate?",
            "I'm doing boxing training tomorrow, want to join?",
            "Just completed 10 rounds! 🥊",
            "My heart rate was in the target zone for 25 minutes today!",
            "Let's compete on Saturday?",
            "Check out my stats from today's training"
        ]
        
        let randomResponse = responses.randomElement() ?? "Hey there!"
        
        let responseMessage = ChatMessage(
            sender: randomUser,
            content: randomResponse,
            isCurrentUser: false,
            timestamp: Date()
        )
        
        messages.append(responseMessage)
    }
    
    private func addReaction(to messageId: UUID, reaction: String) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index].reaction = reaction
        }
    }
    
    private func loadSampleMessages() {
        let sampleMessages: [ChatMessage] = [
            ChatMessage(
                sender: "John",
                content: "Hey everyone! Just finished an amazing boxing session.",
                isCurrentUser: false,
                timestamp: Date().addingTimeInterval(-3600)
            ),
            ChatMessage(
                sender: "You",
                content: "Nice! How many rounds did you do?",
                isCurrentUser: true,
                timestamp: Date().addingTimeInterval(-3500)
            ),
            ChatMessage(
                sender: "John",
                content: "5 rounds of 3 minutes each. My heart rate peaked at 165 BPM! 🔥",
                isCurrentUser: false,
                timestamp: Date().addingTimeInterval(-3400),
                reaction: "🔥"
            ),
            ChatMessage(
                sender: "Maria",
                content: "That's impressive! I'm planning to train tomorrow. Anyone want to join for a virtual session?",
                isCurrentUser: false,
                timestamp: Date().addingTimeInterval(-2800)
            ),
            ChatMessage(
                sender: "You",
                content: "I'm in! What time?",
                isCurrentUser: true,
                timestamp: Date().addingTimeInterval(-2700)
            ),
            ChatMessage(
                sender: "Maria",
                content: "Let's do 6 PM. I'll send a challenge invite!",
                isCurrentUser: false,
                timestamp: Date().addingTimeInterval(-2600)
            )
        ]
        
        messages = sampleMessages
    }
}

// MARK: - Message Bubble View

struct MessageBubble: View {
    let message: ChatMessage
    let onReaction: (String) -> Void
    
    @State private var showActions: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            if message.isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 1) {
                // Sender name
                if !message.isCurrentUser {
                    Text(message.sender)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
                
                // Message content
                HStack {
                    Text(message.content)
                        .font(.footnote)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(message.isCurrentUser ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(message.isCurrentUser ? .white : .primary)
                        .cornerRadius(10)
                        .onTapGesture(count: 2) {
                            showActions = true
                        }
                }
                
                // Reaction if any
                if let reaction = message.reaction {
                    Text(reaction)
                        .font(.callout)
                        .padding(2)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(8)
                        .padding(.top, -4)
                        .padding(.horizontal, message.isCurrentUser ? 0 : 4)
                }
                
                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !message.isCurrentUser {
                Spacer()
            }
        }
        .id(message.id)
        .onTapGesture(count: 2) {
            showActions = true
        }
        .sheet(isPresented: $showActions) {
            VStack(spacing: 20) {
                Text("React to message")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    ForEach(["👍", "🔥", "💪", "👊", "🥊", "🏆"], id: \.self) { emoji in
                        Button(action: {
                            onReaction(emoji)
                            showActions = false
                        }) {
                            Text(emoji)
                                .font(.system(size: 28))
                        }
                    }
                }
                
                Button("Cancel") {
                    showActions = false
                }
                .padding(.top)
            }
            .padding()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .previewDevice("Apple Watch Series 10 (46mm)")
    }
}
#endif
