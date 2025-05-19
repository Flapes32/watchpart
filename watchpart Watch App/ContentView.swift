//
//  ContentView.swift
//  watchpart Watch App
//
//  Created by  Apple on 18.05.2025.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    // State variables
    @State private var heartRate: Int = 0
    @State private var isTrainingActive: Bool = false
    @State private var showTimerSheet: Bool = false
    @State private var showStatsSheet: Bool = false
    @State private var showChallengesSheet: Bool = false
    @State private var showSleepSheet: Bool = false
    @State private var showChatSheet: Bool = false
    @State private var showSleepRecoverySheet: Bool = false
    @State private var heartBeatAnimation: Bool = false
    
    // Target heart rate zone
    @State private var minTargetHR: Int = 120
    @State private var maxTargetHR: Int = 160
    @State private var isInTargetZone: Bool = false
    
    // Timer for updating heart rate
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    // MARK: - Computed properties
    
    private var heartRateColor: Color {
        if heartRate < minTargetHR {
            return .blue // Below target zone
        } else if heartRate > maxTargetHR {
            return .red // Above target zone
        } else {
            return .green // In target zone
        }
    }
    
    private var heartRateZoneText: String {
        if heartRate < minTargetHR {
            return "Below Target"
        } else if heartRate > maxTargetHR {
            return "Above Target"
        } else {
            return "In Target Zone"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    // Heart rate display with zone indicator
                    VStack {
                        Text("Heart Rate")
                            .font(.headline)
                        
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("\(heartRate)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(heartRateColor)
                            
                            Text("BPM")
                                .font(.caption)
                                .offset(y: -5)
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                                .opacity(heartBeatAnimation ? 1.0 : 0.5)
                            
                            Text(heartRateZoneText)
                                .font(.caption2)
                                .foregroundColor(heartRateColor)
                        }
                        
                        // Target zone display
                        Text("Target: \(minTargetHR)-\(maxTargetHR) BPM")
                            .font(.caption)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Quick actions
                    HStack {
                        Button(action: {
                            showTimerSheet = true
                        }) {
                            VStack {
                                Image(systemName: "timer")
                                    .font(.title2)
                                Text("Timer")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .sheet(isPresented: $showTimerSheet) {
                            TimerPlaceholderView()
                        }
                        
                        Button(action: {
                            showStatsSheet = true
                        }) {
                            VStack {
                                Image(systemName: "chart.bar")
                                    .font(.title2)
                                Text("Stats")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .sheet(isPresented: $showStatsSheet) {
                            StatsPlaceholderView()
                        }
                    }
                    
                    // Start training button
                    Button(action: {
                        isTrainingActive.toggle()
                        // Simulate heart rate changes during training
                        if isTrainingActive {
                            heartRate = Int.random(in: 110...170)
                        } else {
                            heartRate = Int.random(in: 65...85)
                        }
                    }) {
                        Text(isTrainingActive ? "Stop Training" : "Start Training")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isTrainingActive ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // Social challenges
                    Button(action: {
                        showChallengesSheet = true
                    }) {
                        HStack {
                            Image(systemName: "person.2")
                                .font(.title2)
                            Text("Challenges")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.black.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .sheet(isPresented: $showChallengesSheet) {
                        ChallengesView()
                    }
                    
                    // Sleep & Recovery tracking
                    Button(action: {
                        showSleepRecoverySheet = true
                    }) {
                        HStack {
                            Image(systemName: "bed.double")
                                .font(.title2)
                            Text("Sleep & Recovery")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .sheet(isPresented: $showSleepRecoverySheet) {
                        SleepRecoveryView()
                    }
                    
                    // Chat with other users
                    Button(action: {
                        showChatSheet = true
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                                .font(.title2)
                            Text("Chat")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.black.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .sheet(isPresented: $showChatSheet) {
                        ChatView()
                    }
                    

                }
                .padding(.horizontal)
            }
            .navigationTitle("Boxing")
            .onAppear {
                // Initialize heart rate
                updateHeartRate()
            }
            .onReceive(timer) { _ in
                if isTrainingActive {
                    updateHeartRate()
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func updateHeartRate() {
        // In a real app, this would come from HealthKit
        if isTrainingActive {
            heartRate = Int.random(in: 110...180)
        } else {
            heartRate = Int.random(in: 65...85)
        }
        
        // Animate heart beat
        withAnimation(.easeInOut(duration: 0.5)) {
            heartBeatAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                heartBeatAnimation = false
            }
        }
        
        // Check if in target zone
        isInTargetZone = (heartRate >= minTargetHR && heartRate <= maxTargetHR)
    }
}

// MARK: - Placeholder Views for future implementation

struct TimerPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Timer View")
                .font(.headline)
            Text("Coming soon")
                .font(.subheadline)
            
            Button("Close") {
                dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 20)
        }
        .padding()
    }
}

struct StatsPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Statistics View")
                .font(.headline)
            Text("Coming soon")
                .font(.subheadline)
            
            Button("Close") {
                dismiss()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 20)
        }
        .padding()
    }
}

struct ChallengesPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Challenges View")
                .font(.headline)
            Text("Coming soon")
                .font(.subheadline)
            
            Button("Close") {
                dismiss()
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 20)
        }
        .padding()
    }
}

struct SleepPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Sleep Tracking View")
                .font(.headline)
            Text("Coming soon")
                .font(.subheadline)
            
            Button("Close") {
                dismiss()
            }
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 20)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
