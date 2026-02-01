import SwiftUI

struct StatsView: View {
    @ObservedObject var timer: PomodoroTimer
    @Environment(\.dismiss) var dismiss
    
    private var theme: AppTheme { timer.theme }
    private var primaryText: Color { theme.primaryTextColor }
    private var secondaryText: Color { theme.secondaryTextColor }
    private var cardBackground: Color { theme.cardBackgroundColor }
    
    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        statsGrid
                        
                        if !timer.taskHistory.isEmpty {
                            historyCard
                        }
                        
                        weeklyProgressCard
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 380, height: 560)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Statistics")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(primaryText)
                Text("Track your productivity")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(secondaryText)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(cardBackground)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "Today",
                value: "\(timer.todayPomodoros)",
                subtitle: "pomodoros",
                icon: "sun.max.fill",
                color: .orange,
                gradient: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                primaryText: primaryText,
                secondaryText: secondaryText
            )
            
            StatCard(
                title: "Focus Time",
                value: formatMinutes(timer.todayFocusMinutes),
                subtitle: "today",
                icon: "clock.fill",
                color: .blue,
                gradient: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                primaryText: primaryText,
                secondaryText: secondaryText
            )
            
            StatCard(
                title: "This Week",
                value: "\(timer.weeklyPomodoros)",
                subtitle: "pomodoros",
                icon: "calendar",
                color: .green,
                gradient: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                primaryText: primaryText,
                secondaryText: secondaryText
            )
            
            StatCard(
                title: "Best Day",
                value: timer.bestDay,
                subtitle: "\(timer.bestDayCount) completed",
                icon: "trophy.fill",
                color: .yellow,
                gradient: [Color.yellow.opacity(0.3), Color.yellow.opacity(0.1)],
                primaryText: primaryText,
                secondaryText: secondaryText
            )
        }
    }
    
    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.purple)
                Text("Recent Tasks")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)
                Spacer()
                Text("\(timer.taskHistory.count) total")
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }
            
            Divider()
                .background(secondaryText.opacity(0.2))
            
            ForEach(Array(timer.taskHistory.prefix(5).enumerated()), id: \.offset) { _, task in
                TaskRow(task: task, theme: theme)
                
                if task.id != timer.taskHistory.prefix(5).last?.id {
                    Divider()
                        .background(secondaryText.opacity(0.1))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
        )
    }
    
    private var weeklyProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cyan)
                Text("Weekly Progress")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)
                Spacer()
                Text("\(timer.weeklyFocusMinutes) min")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.cyan)
            }
            
            Divider()
                .background(secondaryText.opacity(0.2))
            
            WeeklyBarChart(theme: theme)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
        )
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let gradient: [Color]
    let primaryText: Color
    let secondaryText: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(primaryText)
                
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(secondaryText)
                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(secondaryText.opacity(0.5))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText.opacity(0.7))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: gradient),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

struct TaskRow: View {
    let task: TaskRecord
    let theme: AppTheme
    
    private var primaryText: Color { theme.primaryTextColor }
    private var secondaryText: Color { theme.secondaryTextColor }
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(task.mode.color(for: theme).opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: task.mode.icon)
                        .font(.system(size: 12))
                        .foregroundColor(task.mode.color(for: theme))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name.isEmpty ? "Focus Session" : task.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                
                Text(formatDate(task.date))
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }
            
            Spacer()
            
            Text(formatDuration(task.duration))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(secondaryText)
                .monospacedDigit()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}

struct WeeklyBarChart: View {
    let theme: AppTheme
    @State private var days: [DayData] = []
    
    private var primaryText: Color { theme.primaryTextColor }
    private var secondaryText: Color { theme.secondaryTextColor }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(days) { day in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(day.color)
                        .frame(width: 32, height: barHeight(for: day.count))
                        .animation(.easeInOut(duration: 0.3), value: day.count)
                    
                    Text(day.shortName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(secondaryText)
                }
            }
        }
        .frame(height: 80)
        .onAppear(perform: loadData)
    }
    
    private func barHeight(for count: Int) -> CGFloat {
        let maxHeight: CGFloat = 60
        guard days.map({ $0.count }).max() ?? 1 > 0 else { return 8 }
        let maxCount = CGFloat(days.map({ $0.count }).max() ?? 1)
        return max(8, CGFloat(count) / maxCount * maxHeight)
    }
    
    private func loadData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        var newDays: [DayData] = []
        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            var count = 0
            if let data = UserDefaults.standard.data(forKey: "todayStats"),
               let stats = try? JSONDecoder().decode(StatsRecord.self, from: data),
               calendar.isDate(stats.date, inSameDayAs: date) {
                count = stats.completed
            }
            
            let isToday = calendar.isDateInToday(date)
            let color: Color = isToday ? .cyan : (count > 0 ? .purple : secondaryText.opacity(0.2))
            
            newDays.append(DayData(
                name: formatter.string(from: date),
                count: count,
                color: color,
                isToday: isToday
            ))
        }
        days = newDays
    }
}

struct DayData: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let color: Color
    let isToday: Bool
    
    var shortName: String { name }
}

#Preview {
    StatsView(timer: PomodoroTimer())
}
