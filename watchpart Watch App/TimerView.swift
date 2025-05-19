//
//  TimerView.swift
//  watchpart Watch App
//
//  Created by Apple on 19.05.2025.
//

import SwiftUI
import UserNotifications

struct TimerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    // Timer settings
    @State private var roundDuration: Int = 180 // 3 minutes in seconds
    @State private var restDuration: Int = 60 // 1 minute in seconds
    @State private var numberOfRounds: Int = 3
    
    // Timer state
    @State private var isTimerRunning: Bool = false
    @State private var currentRound: Int = 1
    @State private var isRestPeriod: Bool = false
    @State private var timeRemaining: Int = 180
    @State private var progress: Double = 1.0
    @State private var showSettings: Bool = false
    
    // Colors
    private let activeColor: Color = .blue
    private let restColor: Color = .orange
    private let completedColor: Color = .green
    
    // Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 15) {
            // Status text
            Text(statusText)
                .font(.headline)
                .foregroundColor(isRestPeriod ? restColor : activeColor)
            
            // Timer display
            ZStack {
                // Outer circle (background)
                Circle()
                    .stroke(lineWidth: 15)
                    .opacity(0.3)
                    .foregroundColor(isRestPeriod ? restColor : activeColor)
                
                // Progress circle
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                    .foregroundColor(isRestPeriod ? restColor : activeColor)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: progress)
                
                // Time remaining
                VStack {
                    Text(timeString(timeRemaining))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(isRestPeriod ? restColor : activeColor)
                    
                    Text("Round \(currentRound)/\(numberOfRounds)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 150, height: 150)
            .padding()
            
            // Control buttons
            HStack(spacing: 20) {
                // Start/Pause button
                Button(action: {
                    isTimerRunning.toggle()
                    if isTimerRunning {
                        requestNotificationPermission()
                    }
                }) {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(isTimerRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                
                // Reset button
                Button(action: resetTimer) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            
            // Settings button
            Button(action: {
                showSettings = true
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.top, 10)
            .sheet(isPresented: $showSettings) {
                timerSettingsView
            }
        }
        .padding()
        .onAppear {
            resetTimer()
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // App came to foreground
            } else if newPhase == .background {
                // App went to background - schedule notifications if timer is running
                if isTimerRunning {
                    scheduleNotification()
                }
            }
        }
        .navigationTitle("Timer")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Timer Settings View
    
    private var timerSettingsView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Round Settings")) {
                    Stepper(value: $roundDuration, in: 60...300, step: 30) {
                        HStack {
                            Text("Round Duration")
                            Spacer()
                            Text(formatDuration(roundDuration))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Stepper(value: $restDuration, in: 30...120, step: 10) {
                        HStack {
                            Text("Rest Duration")
                            Spacer()
                            Text(formatDuration(restDuration))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Stepper(value: $numberOfRounds, in: 1...12) {
                        HStack {
                            Text("Number of Rounds")
                            Spacer()
                            Text("\(numberOfRounds)")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    Button("Apply Settings") {
                        resetTimer()
                        showSettings = false
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
                
                Section {
                    Button("Cancel") {
                        showSettings = false
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Timer Settings")
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        if !isTimerRunning && timeRemaining == roundDuration && currentRound == 1 {
            return "Ready to Start"
        } else if isRestPeriod {
            return "Rest"
        } else if currentRound > numberOfRounds {
            return "Workout Complete!"
        } else {
            return "Round \(currentRound)"
        }
    }
    
    // MARK: - Methods
    
    private func updateTimer() {
        guard isTimerRunning else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
            updateProgress()
        } else {
            handleTimerCompletion()
        }
    }
    
    private func handleTimerCompletion() {
        if isRestPeriod {
            // Rest period is over, start next round
            isRestPeriod = false
            currentRound += 1
            
            if currentRound <= numberOfRounds {
                // Start next round
                timeRemaining = roundDuration
                updateProgress()
                playSound(isRestPeriod: false)
            } else {
                // Workout complete
                isTimerRunning = false
                playSound(isRestPeriod: false)
            }
        } else {
            // Round is over
            if currentRound < numberOfRounds {
                // Start rest period
                isRestPeriod = true
                timeRemaining = restDuration
                updateProgress()
                playSound(isRestPeriod: true)
            } else {
                // Final round complete
                isTimerRunning = false
                playSound(isRestPeriod: false)
            }
        }
    }
    
    private func updateProgress() {
        let totalDuration = isRestPeriod ? restDuration : roundDuration
        progress = Double(timeRemaining) / Double(totalDuration)
    }
    
    private func resetTimer() {
        isTimerRunning = false
        currentRound = 1
        isRestPeriod = false
        timeRemaining = roundDuration
        progress = 1.0
    }
    
    private func timeString(_ time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if remainingSeconds == 0 {
            return "\(minutes)m"
        } else {
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
    
    // MARK: - Notification Methods
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        
        if isRestPeriod {
            content.title = "Rest Period Ending"
            content.body = "Get ready for Round \(currentRound + 1)!"
        } else if currentRound < numberOfRounds {
            content.title = "Round \(currentRound) Ending"
            content.body = "Rest period starting soon!"
        } else {
            content.title = "Final Round Ending"
            content.body = "Workout complete!"
        }
        
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timeRemaining), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func playSound(isRestPeriod: Bool) {
        // In a real app, implement sound playback here
        // For watchOS, you would use WKInterfaceSoundPlay or similar APIs
        print("Playing sound: \(isRestPeriod ? "Rest period" : "Round")")
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
    }
}
