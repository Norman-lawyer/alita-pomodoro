import SwiftUI
import Combine
import UserNotifications

enum TimerState: String {
    case idle = "Idle"
    case running = "Running"
    case paused = "Paused"
    case complete = "Complete"
    
    var display: String {
        switch self {
        case .idle: return "Ready"
        case .running: return "Focus"
        case .paused: return "Paused"
        case .complete: return "Complete"
        }
    }
}

class PomodoroTimer: ObservableObject {
    @Published var currentMode: TimerMode = .work {
        didSet {
            updateSound()
        }
    }
    @Published var theme: AppTheme = .dark
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var state: TimerState = .idle
    @Published var completedPomodoros: Int = 0
    @Published var completedBreaks: Int = 0
    @Published var todayPomodoros: Int = 0
    @Published var todayFocusMinutes: Int = 0
    @Published var currentTask: String = ""
    @Published var taskHistory: [TaskRecord] = []
    
    private var timer: Timer?
    private var totalDuration: TimeInterval = 25 * 60
    private var pomodorosUntilLongBreak: Int = 4
    private var autoStartBreaks: Bool = false
    private let audioManager = AudioManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSettings()
        loadTodayStats()
        setupNotifications()
        setupKeyBindings()
    }
    
    // MARK: - Settings Loading
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Set defaults if first launch
        if defaults.object(forKey: "workDuration") == nil {
            defaults.set(25, forKey: "workDuration")
        }
        if defaults.object(forKey: "shortBreakDuration") == nil {
            defaults.set(5, forKey: "shortBreakDuration")
        }
        if defaults.object(forKey: "longBreakDuration") == nil {
            defaults.set(15, forKey: "longBreakDuration")
        }
        if defaults.object(forKey: "pomodorosUntilLongBreak") == nil {
            defaults.set(4, forKey: "pomodorosUntilLongBreak")
        }
        if defaults.object(forKey: "autoStartBreaks") == nil {
            defaults.set(false, forKey: "autoStartBreaks")
        }
        
        pomodorosUntilLongBreak = defaults.integer(forKey: "pomodorosUntilLongBreak")
        autoStartBreaks = defaults.bool(forKey: "autoStartBreaks")
        
        if state == .idle {
            timeRemaining = currentMode.duration
        }
        
        // Load audio settings
        audioManager.enabled = defaults.bool(forKey: "soundEnabled")
        audioManager.setVolume(Float(defaults.double(forKey: "soundVolume")))
    }
    
    private func loadTodayStats() {
        let today = Calendar.current.startOfDay(for: Date())
        if let data = UserDefaults.standard.data(forKey: "todayStats"),
           let stats = try? JSONDecoder().decode(StatsRecord.self, from: data),
           Calendar.current.isDate(stats.date, inSameDayAs: today) {
            todayPomodoros = stats.completed
            todayFocusMinutes = stats.focusMinutes
        }
    }
    
    private func saveTodayStats() {
        let stats = StatsRecord(
            date: Calendar.current.startOfDay(for: Date()),
            completed: todayPomodoros,
            focusMinutes: todayFocusMinutes
        )
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: "todayStats")
        }
    }
    
    private func loadTaskHistory() {
        if let data = UserDefaults.standard.data(forKey: "taskHistory"),
           let history = try? JSONDecoder().decode([TaskRecord].self, from: data) {
            taskHistory = history
        }
    }
    
    private func saveTaskHistory() {
        if let data = try? JSONEncoder().encode(taskHistory) {
            UserDefaults.standard.set(data, forKey: "taskHistory")
        }
    }
    
    // MARK: - Timer Control
    
    func start() {
        guard state != .running else { return }
        state = .running
        totalDuration = timeRemaining
        audioManager.play(currentMode.sound)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()
        timer = nil
        audioManager.stop()
    }
    
    func resume() {
        guard state == .paused else { return }
        state = .running
        audioManager.play(currentMode.sound)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = currentMode.duration
        audioManager.stop()
    }
    
    func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = currentMode.duration
        audioManager.stop()
    }
    
    func skip() {
        timer?.invalidate()
        timer = nil
        completePhase()
    }
    
    func setMode(_ mode: TimerMode) {
        timer?.invalidate()
        timer = nil
        currentMode = mode
        state = .idle
        timeRemaining = mode.duration
        DispatchQueue.main.async {
            self.audioManager.stop()
        }
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completePhase()
        }
    }
    
    private func completePhase() {
        let wasWork = currentMode == .work
        
        if wasWork {
            completedPomodoros += 1
            todayPomodoros += 1
            todayFocusMinutes += Int(totalDuration / 60)
            saveTodayStats()
            
            // Save task history
            if !currentTask.isEmpty {
                let record = TaskRecord(
                    name: currentTask,
                    date: Date(),
                    duration: totalDuration,
                    mode: currentMode
                )
                taskHistory.insert(record, at: 0)
                if taskHistory.count > 100 { taskHistory.removeLast() }
                saveTaskHistory()
            }
            
            // Determine next mode
            if completedPomodoros % pomodorosUntilLongBreak == 0 {
                currentMode = .longBreak
                state = .complete
            } else {
                currentMode = .shortBreak
                state = .complete
            }
            
            completedBreaks += 1
            sendNotification(title: "Pomodoro Complete! 🎉", body: "Time for a break!")
        } else {
            currentMode = .work
            state = .complete
            sendNotification(title: "Break Over! 💪", body: "Ready to focus again?")
        }
        
        timeRemaining = currentMode.duration
        totalDuration = timeRemaining
        audioManager.stop()
        
        // Pulse animation trigger
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.state = .complete
        }
        
        // Auto-start if enabled
        if autoStartBreaks && wasWork {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.start()
            }
        }
    }
    
    // MARK: - Sound
    
    private func updateSound() {
        if state == .running {
            audioManager.play(currentMode.sound)
        }
    }
    
    // MARK: - Computed Properties
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1 - (timeRemaining / totalDuration)
    }
    
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var stateDisplay: String {
        return state.display
    }
    
    var weeklyPomodoros: Int {
        let calendar = Calendar.current
        let now = Date()
        var total = 0
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                if let data = UserDefaults.standard.data(forKey: "todayStats"),
                   let stats = try? JSONDecoder().decode(StatsRecord.self, from: data),
                   calendar.isDate(stats.date, inSameDayAs: date) {
                    total += stats.completed
                }
            }
        }
        return total
    }
    
    var weeklyFocusMinutes: Int {
        let calendar = Calendar.current
        let now = Date()
        var total = 0
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                if let data = UserDefaults.standard.data(forKey: "todayStats"),
                   let stats = try? JSONDecoder().decode(StatsRecord.self, from: data),
                   calendar.isDate(stats.date, inSameDayAs: date) {
                    total += stats.focusMinutes
                }
            }
        }
        return total
    }
    
    var bestDay: String {
        let calendar = Calendar.current
        let now = Date()
        var maxCount = 0
        var bestDay = "N/A"
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                if let data = UserDefaults.standard.data(forKey: "todayStats"),
                   let stats = try? JSONDecoder().decode(StatsRecord.self, from: data),
                   calendar.isDate(stats.date, inSameDayAs: date) {
                    if stats.completed > maxCount {
                        maxCount = stats.completed
                        let formatter = DateFormatter()
                        formatter.dateFormat = "EEE"
                        bestDay = formatter.string(from: date)
                    }
                }
            }
        }
        return bestDay
    }
    
    var bestDayCount: Int {
        let calendar = Calendar.current
        let now = Date()
        var maxCount = 0
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                if let data = UserDefaults.standard.data(forKey: "todayStats"),
                   let stats = try? JSONDecoder().decode(StatsRecord.self, from: data),
                   calendar.isDate(stats.date, inSameDayAs: date) {
                    if stats.completed > maxCount {
                        maxCount = stats.completed
                    }
                }
            }
        }
        return maxCount
    }
    
    var longestStreak: Int {
        // Simplified streak calculation
        let calendar = Calendar.current
        var streak = 0
        var date = Date()
        
        while true {
            if let data = UserDefaults.standard.data(forKey: "todayStats"),
               let stats = try? JSONDecoder().decode(StatsRecord.self, from: data),
               calendar.isDate(stats.date, inSameDayAs: date),
               stats.completed > 0 {
                streak += 1
                date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            } else {
                break
            }
        }
        return streak
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Keyboard Shortcuts
    
    private func setupKeyBindings() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return nil }
            
            if event.modifierFlags.contains(.command) {
                switch event.keyCode {
                case 49: // Space - Play/Pause
                    self.handleKeyPress(.space)
                    return nil
                case 35: // P - Pause
                    if event.characters == "p" {
                        self.pause()
                        return nil
                    }
                case 46: // R - Reset
                    if event.characters == "r" {
                        self.reset()
                        return nil
                    }
                case 41: // S - Skip
                    if event.characters == "s" {
                        self.skip()
                        return nil
                    }
                default:
                    break
                }
            } else {
                // Space without command for play/pause
                if event.keyCode == 49 && !event.isARepeat {
                    self.handleKeyPress(.space)
                    return nil
                }
            }
            
            return event
        }
    }
    
    private func handleKeyPress(_ key: Key) {
        switch key {
        case .space:
            switch state {
            case .idle: start()
            case .running: pause()
            case .paused: resume()
            default: break
            }
        default: break
        }
    }
    
    enum Key {
        case space
    }
}

// MARK: - Supporting Types

struct StatsRecord: Codable {
    var date: Date
    var completed: Int
    var focusMinutes: Int
}

struct TaskRecord: Codable, Identifiable {
    var id: String { UUID().uuidString }
    var name: String
    var date: Date
    var duration: TimeInterval
    var mode: TimerMode
}
