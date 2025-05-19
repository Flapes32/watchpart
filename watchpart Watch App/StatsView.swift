//
//  StatsView.swift
//  watchpart Watch App
//
//  Created by Apple on 19.05.2025.
//

import SwiftUI
import Charts

struct TrainingSession: Identifiable {
    let id = UUID()
    let date: Date
    let duration: Int // in minutes
    let avgHeartRate: Int
    let maxHeartRate: Int
    let caloriesBurned: Int
}

struct StatsView: View {
    @Environment(\.dismiss) var dismiss
    
    // Sample data - in a real app, this would come from persistent storage
    @State private var trainingSessions: [TrainingSession] = [
        TrainingSession(
            date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            duration: 45,
            avgHeartRate: 145,
            maxHeartRate: 168,
            caloriesBurned: 320
        ),
        TrainingSession(
            date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            duration: 30,
            avgHeartRate: 138,
            maxHeartRate: 155,
            caloriesBurned: 210
        ),
        TrainingSession(
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            duration: 60,
            avgHeartRate: 152,
            maxHeartRate: 175,
            caloriesBurned: 450
        ),
        TrainingSession(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            duration: 40,
            avgHeartRate: 142,
            maxHeartRate: 162,
            caloriesBurned: 280
        )
    ]
    
    @State private var selectedTimeFrame: TimeFrame = .week
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                // Header with time frame selector
                HStack {
                    Text("Statistics")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    HStack(spacing: 5) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Button(action: {
                                selectedTimeFrame = timeFrame
                            }) {
                                Text(timeFrame.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedTimeFrame == timeFrame ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(selectedTimeFrame == timeFrame ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Summary cards
                summaryCardsView
                
                // Heart rate chart
                heartRateChartView
                
                // Training duration chart
                trainingDurationChartView
                
                // Recent sessions list
                recentSessionsView
            }
            .padding(.vertical)
        }
        .navigationTitle("Stats")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Summary Cards View
    
    private var summaryCardsView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Total sessions card
                statCard(
                    title: "Sessions",
                    value: "\(trainingSessions.count)",
                    icon: "figure.boxing",
                    color: .blue
                )
                
                // Average heart rate card
                statCard(
                    title: "Avg HR",
                    value: "\(averageHeartRate) BPM",
                    icon: "heart.fill",
                    color: .red
                )
            }
            
            HStack(spacing: 10) {
                // Total duration card
                statCard(
                    title: "Total Time",
                    value: formatTotalDuration,
                    icon: "clock.fill",
                    color: .green
                )
                
                // Total calories card
                statCard(
                    title: "Calories",
                    value: "\(totalCaloriesBurned)",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Heart Rate Chart View
    
    private var heartRateChartView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Heart Rate")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(filteredSessions) { session in
                    BarMark(
                        x: .value("Date", formatDate(session.date)),
                        y: .value("Avg HR", session.avgHeartRate)
                    )
                    .foregroundStyle(Color.red.gradient)
                    
                    RuleMark(
                        x: .value("Date", formatDate(session.date)),
                        yStart: .value("Min HR", session.avgHeartRate - 10),
                        yEnd: .value("Max HR", session.maxHeartRate)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .foregroundStyle(Color.red.opacity(0.5))
                    
                    PointMark(
                        x: .value("Date", formatDate(session.date)),
                        y: .value("Max HR", session.maxHeartRate)
                    )
                    .foregroundStyle(Color.red)
                }
            }
            .frame(height: 150)
            .padding(.horizontal)
            .chartYScale(domain: 100...190)
        }
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Training Duration Chart View
    
    private var trainingDurationChartView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Training Duration")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(filteredSessions) { session in
                    BarMark(
                        x: .value("Date", formatDate(session.date)),
                        y: .value("Duration", session.duration)
                    )
                    .foregroundStyle(Color.green.gradient)
                }
            }
            .frame(height: 150)
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Recent Sessions View
    
    private var recentSessionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Sessions")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(filteredSessions.prefix(3)) { session in
                HStack {
                    VStack(alignment: .leading) {
                        Text(formatDateFull(session.date))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(session.duration) min • \(session.avgHeartRate) BPM avg")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text("\(session.caloriesBurned) cal")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods and Computed Properties
    
    private var filteredSessions: [TrainingSession] {
        switch selectedTimeFrame {
        case .week:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            return trainingSessions.filter { $0.date >= oneWeekAgo }
        case .month:
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            return trainingSessions.filter { $0.date >= oneMonthAgo }
        case .year:
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            return trainingSessions.filter { $0.date >= oneYearAgo }
        }
    }
    
    private var averageHeartRate: Int {
        guard !filteredSessions.isEmpty else { return 0 }
        let sum = filteredSessions.reduce(0) { $0 + $1.avgHeartRate }
        return sum / filteredSessions.count
    }
    
    private var totalDuration: Int {
        filteredSessions.reduce(0) { $0 + $1.duration }
    }
    
    private var formatTotalDuration: String {
        let hours = totalDuration / 60
        let minutes = totalDuration % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var totalCaloriesBurned: Int {
        filteredSessions.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
