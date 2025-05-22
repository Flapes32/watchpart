import SwiftUI
import UserNotifications
import WatchConnectivity
import WatchKit

struct TimerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    // WatchConnectivity manager
    @ObservedObject var wcHandler = WatchConnectivityHandler.shared
    
    // Timer settings
    @State private var roundDuration: Int = 180 // 3 minutes in seconds
    @State private var restDuration: Int = 60 // 1 minute in seconds
    @State private var numberOfRounds: Int = 6
    
    // Timer state
    @State private var isTimerRunning: Bool = false
    @State private var currentRound: Int = 1
    @State private var isRestPeriod: Bool = false
    @State private var timeRemaining: Int = 180
    @State private var progress: Double = 1.0
    @State private var showSettings: Bool = false
    @State private var workoutComplete: Bool = false
    
    // Colors
    private let activeColor: Color = .blue
    private let restColor: Color = .green
    private let completedColor: Color = .orange
    
    // Timer
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
                    
                    if !workoutComplete {
                        Text("Round \(currentRound)/\(numberOfRounds)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: 150, height: 150)
            .padding()
            
            // Control buttons
            HStack(spacing: 20) {
                // Start/Pause button
                if !workoutComplete {
                    Button(action: {
                        isTimerRunning.toggle()
                        
                        if isTimerRunning {
                            // Reconnect timer if it was disconnected
                            timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                            requestNotificationPermission()
                            
                            // Start workout in WatchConnectivityHandler
                            if currentRound == 1 && !isRestPeriod && timeRemaining == roundDuration {
                                wcHandler.startWorkout()
                            } else if wcHandler.isWorkoutPaused {
                                wcHandler.resumeWorkout()
                            }
                            
                            // Haptic feedback when starting
                            WKInterfaceDevice.current().play(.start)
                        } else {
                            // Pause workout in WatchConnectivityHandler
                            wcHandler.pauseWorkout()
                            
                            // Haptic feedback when pausing
                            WKInterfaceDevice.current().play(.stop)
                        }
                    }) {
                        Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .frame(width: 50, height: 50)
                            .background(isTimerRunning ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                } else {
                    // End workout button when complete
                    Button("End Workout") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                
                // Reset button (only show if not complete)
                if !workoutComplete {
                    Button(action: {
                        resetTimer()
                        
                        // Stop workout in WatchConnectivityHandler
                        wcHandler.stopWorkout()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                            .frame(width: 50, height: 50)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
            }
            
            // Settings button (only show if not running and not complete)
            if !isTimerRunning && !workoutComplete {
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
        }
        .padding()
        .onAppear {
            // Apply timer settings from iPhone
            applyTimerSettings()
            
            // Reset timer
            resetTimer()
        }
        .onChange(of: wcHandler.timerSettings) { _, newSettings in
            // Update timer settings when receiving new data from iPhone
            applyTimerSettings()
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
                    VStack {
                        HStack {
                            Text("Round Duration")
                            Spacer()
                            Text(formatDuration(roundDuration))
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("1 min")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Slider(value: Binding(
                                get: { Double(roundDuration) / 60.0 },
                                set: { roundDuration = Int($0 * 60) }
                            ), in: 1...10, step: 0.5)
                            
                            Text("10 min")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    VStack {
                        HStack {
                            Text("Rest Duration")
                            Spacer()
                            Text(formatDuration(restDuration))
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("30 sec")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Slider(value: Binding(
                                get: { Double(restDuration) / 60.0 },
                                set: { restDuration = Int($0 * 60) }
                            ), in: 0.5...2, step: 0.5)
                            
                            Text("2 min")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    VStack {
                        HStack {
                            Text("Number of Rounds")
                            Spacer()
                            Text("\(numberOfRounds)")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("1")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Slider(value: Binding(
                                get: { Double(numberOfRounds) },
                                set: { numberOfRounds = Int($0) }
                            ), in: 1...12, step: 1)
                            
                            Text("12")
                                .font(.caption)
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
        if workoutComplete {
            return "Workout Complete!"
        } else if !isTimerRunning && timeRemaining == roundDuration && currentRound == 1 {
            return "Ready to Start"
        } else if isRestPeriod {
            return "Rest"
        } else {
            return "Round \(currentRound)"
        }
    }
    
    // MARK: - Methods
    
    // Apply timer settings from iPhone
    private func applyTimerSettings() {
        let settings = wcHandler.timerSettings
        roundDuration = settings.roundDuration
        restDuration = settings.restDuration
        numberOfRounds = settings.numberOfRounds
        
        // If timer is not running, reset it with new settings
        if !isTimerRunning {
            resetTimer()
        }
    }
    
    private func updateTimer() {
        guard isTimerRunning else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
            progress = Double(timeRemaining) / Double(isRestPeriod ? restDuration : roundDuration)
        } else {
            // Play sound when timer completes
            WKInterfaceDevice.current().play(.notification)
            
            // Round or rest period completed
            if isRestPeriod {
                // Rest period completed, move to next round
                if currentRound < numberOfRounds {
                    currentRound += 1
                    isRestPeriod = false
                    timeRemaining = roundDuration
                    progress = 1.0
                    
                    // Increment round counter in WatchConnectivityHandler
                    wcHandler.incrementRound()
                } else {
                    // Workout completed
                    isTimerRunning = false
                    workoutComplete = true
                    
                    // Stop workout in WatchConnectivityHandler
                    wcHandler.stopWorkout()
                }
            } else {
                // Round completed, move to rest period
                isRestPeriod = true
                timeRemaining = restDuration
                progress = 1.0
            }
        }
    }
    
    private func resetTimer() {
        isTimerRunning = false
        currentRound = 1
        isRestPeriod = false
        timeRemaining = roundDuration
        progress = 1.0
        workoutComplete = false
        
        // Haptic feedback for reset
        WKInterfaceDevice.current().play(.click)
    }
    
    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
    
    private func showAlert(title: String, message: String) {
        // In a real app, you would show an alert here
        print("\(title): \(message)")
    }
    
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
        content.title = "Boxing Timer"
        
        if isRestPeriod {
            content.body = "Rest period is over. Get ready for round \(currentRound + 1)!"
        } else if currentRound < numberOfRounds {
            content.body = "Round \(currentRound) is over. Time to rest!"
        } else {
            content.body = "Congratulations! You've completed your workout."
        }
        
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timeRemaining), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
    }
}
