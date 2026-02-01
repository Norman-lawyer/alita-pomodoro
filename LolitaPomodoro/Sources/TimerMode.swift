import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case dark = "Dark"
    case light = "Light"
    
    var displayName: String { rawValue }
    
    var backgroundColor: Color {
        switch self {
        case .dark: return Color(red: 0.08, green: 0.08, blue: 0.10)
        case .light: return Color(red: 0.96, green: 0.96, blue: 0.98)
        }
    }
    
    var cardBackgroundColor: Color {
        switch self {
        case .dark: return Color.white.opacity(0.05)
        case .light: return Color.black.opacity(0.05)
        }
    }
    
    var primaryTextColor: Color {
        switch self {
        case .dark: return .white
        case .light: return Color(red: 0.15, green: 0.15, blue: 0.18)
        }
    }
    
    var secondaryTextColor: Color {
        switch self {
        case .dark: return .white.opacity(0.5)
        case .light: return Color(red: 0.15, green: 0.15, blue: 0.18).opacity(0.5)
        }
    }
    
    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
}

enum TimerMode: String, CaseIterable, Codable {
    case work, shortBreak, longBreak
    
    var shortTitle: String {
        switch self {
        case .work: return "Focus"
        case .shortBreak: return "Short"
        case .longBreak: return "Long"
        }
    }
    
    var icon: String {
        switch self {
        case .work: return "brain.head.profile"
        case .shortBreak: return "leaf.fill"
        case .longBreak: return "moon.fill"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .work: return UserDefaults.standard.double(forKey: "workDuration") * 60
        case .shortBreak: return UserDefaults.standard.double(forKey: "shortBreakDuration") * 60
        case .longBreak: return UserDefaults.standard.double(forKey: "longBreakDuration") * 60
        }
    }
    
    func color(for theme: AppTheme) -> Color {
        switch self {
        case .work: return Color(red: 0.95, green: 0.35, blue: 0.40)
        case .shortBreak: return Color(red: 0.35, green: 0.85, blue: 0.60)
        case .longBreak: return Color(red: 0.45, green: 0.55, blue: 0.95)
        }
    }
    
    func backgroundColor(for theme: AppTheme) -> Color {
        switch self {
        case .work: return Color(red: 0.95, green: 0.35, blue: 0.40).opacity(theme == .dark ? 0.15 : 0.1)
        case .shortBreak: return Color(red: 0.35, green: 0.85, blue: 0.60).opacity(theme == .dark ? 0.15 : 0.1)
        case .longBreak: return Color(red: 0.45, green: 0.55, blue: 0.95).opacity(theme == .dark ? 0.15 : 0.1)
        }
    }
    
    var sound: PomodoroSound {
        switch self {
        case .work:
            if let sound = UserDefaults.standard.string(forKey: "focusSound"),
               let parsed = PomodoroSound(rawValue: sound) {
                return parsed
            }
            return .ticking
        case .shortBreak:
            if let sound = UserDefaults.standard.string(forKey: "shortBreakSound"),
               let parsed = PomodoroSound(rawValue: sound) {
                return parsed
            }
            return .forest
        case .longBreak:
            if let sound = UserDefaults.standard.string(forKey: "longBreakSound"),
               let parsed = PomodoroSound(rawValue: sound) {
                return parsed
            }
            return .ocean
        }
    }
}
