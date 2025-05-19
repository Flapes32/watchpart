import SwiftUI

struct SleepRecoveryView: View {
    // Sample data
    @State private var sleepHours: Double = 7.2
    @State private var sleepQuality: Double = 0.75
    @State private var recoveryScore: Int = 82
    @State private var restingHeartRate: Int = 58
    @State private var hrVariability: Int = 48
    
    // Sleep data for the week
    @State private var weeklySleepData: [Double] = [6.8, 7.5, 6.2, 8.1, 7.2, 7.0, 7.8]
    
    // Tab selection
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Overview tab
            VStack(spacing: 8) {
                Text("Sleep & Recovery")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.top, 4)
                
                // Recovery score circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(recoveryScore) / 100)
                        .stroke(
                            recoveryScore > 80 ? Color.green :
                                recoveryScore > 60 ? Color.yellow : Color.red,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(recoveryScore)")
                            .font(.system(size: 24, weight: .bold))
                        Text("Recovery")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
                
                // Key metrics
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.blue)
                        Text(String(format: "%.1f hrs", sleepHours))
                        Spacer()
                        qualityIndicator(quality: sleepQuality)
                    }
                    .font(.system(size: 14))
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("\(restingHeartRate) bpm")
                        Spacer()
                        Text("Resting")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .font(.system(size: 14))
                    
                    HStack {
                        Image(systemName: "waveform.path")
                            .foregroundColor(.purple)
                        Text("\(hrVariability) ms")
                        Spacer()
                        Text("HRV")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .font(.system(size: 14))
                }
                .padding(.horizontal, 10)
                
                // Recommendation
                Text(recoveryRecommendation)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .foregroundColor(
                        recoveryScore > 80 ? .green :
                            recoveryScore > 60 ? .yellow : .red
                    )
            }
            .tag(0)
            
            // Sleep history tab
            VStack(spacing: 8) {
                Text("Sleep History")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.top, 4)
                
                // Weekly sleep chart
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<weeklySleepData.count, id: \.self) { index in
                        VStack {
                            // Bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(hours: weeklySleepData[index]))
                                .frame(width: 12, height: CGFloat(weeklySleepData[index] * 8))
                            
                            // Day
                            Text(dayLabel(for: index))
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Weekly average
                HStack {
                    Text("Weekly Average:")
                        .font(.system(size: 14))
                    
                    Text(String(format: "%.1f hrs", weeklySleepData.reduce(0, +) / Double(weeklySleepData.count)))
                        .font(.system(size: 14, weight: .semibold))
                }
                
                // Sleep debt calculation
                let sleepDebt = max(0, (8.0 * 7) - weeklySleepData.reduce(0, +))
                
                if sleepDebt > 0 {
                    HStack {
                        Text("Sleep Debt:")
                            .font(.system(size: 14))
                        
                        Text(String(format: "%.1f hrs", sleepDebt))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
                
                // Tips
                Text(sleepTip)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .foregroundColor(.blue)
            }
            .tag(1)
            
            // Recovery trends tab
            VStack(spacing: 8) {
                Text("Recovery Trends")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.top, 4)
                
                // Recovery score history
                HStack {
                    Text("Last 7 days:")
                        .font(.system(size: 12))
                    
                    // Simplified trend visualization
                    HStack(spacing: 2) {
                        ForEach(0..<7) { i in
                            Circle()
                                .fill(trendColor(index: i))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Key recovery factors
                VStack(spacing: 8) {
                    recoveryFactor(name: "Sleep Quality", value: 75, color: .blue)
                    recoveryFactor(name: "Training Load", value: 68, color: .orange)
                    recoveryFactor(name: "Stress Level", value: 42, color: .green)
                    recoveryFactor(name: "Nutrition", value: 80, color: .purple)
                }
                .padding(.horizontal, 10)
                
                // Recommendation
                Text("Focus on reducing stress levels to improve recovery")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .foregroundColor(.blue)
            }
            .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
    }
    
    // Helper views and functions
    private func qualityIndicator(quality: Double) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(
                        Double(star) <= quality * 5 ? .yellow : .gray.opacity(0.3)
                    )
            }
        }
    }
    
    private func barColor(hours: Double) -> Color {
        if hours >= 8 { return .green }
        if hours >= 6 { return .blue }
        if hours >= 5 { return .yellow }
        return .red
    }
    
    private func dayLabel(for index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }
    
    private func trendColor(index: Int) -> Color {
        // Simulated recovery scores
        let scores = [75, 82, 68, 90, 85, 78, 82]
        let score = scores[index]
        
        if score >= 80 { return .green }
        if score >= 60 { return .yellow }
        return .red
    }
    
    private func recoveryFactor(name: String, value: Int, color: Color) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 12))
            
            Spacer()
            
            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 8)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 80 * CGFloat(value) / 100, height: 8)
            }
            
            Text("\(value)%")
                .font(.system(size: 12))
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    // Dynamic recommendations based on recovery score
    private var recoveryRecommendation: String {
        if recoveryScore > 80 {
            return "Ready for high-intensity training. Push yourself today!"
        } else if recoveryScore > 60 {
            return "Moderate training recommended. Focus on technique."
        } else {
            return "Recovery day advised. Light activity only."
        }
    }
    
    // Random sleep tip
    private var sleepTip: String {
        let tips = [
            "Avoid screens 1 hour before bed for better sleep quality",
            "Consistent sleep/wake times improve recovery",
            "Keep your bedroom cool (65-68°F) for optimal sleep",
            "Limit caffeine after 2pm to improve sleep quality"
        ]
        return tips[Int.random(in: 0..<tips.count)]
    }
}

// MARK: - Preview
#if DEBUG
struct SleepRecoveryView_Previews: PreviewProvider {
    static var previews: some View {
        SleepRecoveryView()
            .previewDevice("Apple Watch Series 10 (46mm)")
    }
}
#endif
