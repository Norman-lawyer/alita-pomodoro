import SwiftUI

struct SettingsView: View {
    @ObservedObject var timer: PomodoroTimer
    @Environment(\.dismiss) var dismiss
    
    @State private var workDuration: Double = 25
    @State private var shortBreakDuration: Double = 5
    @State private var longBreakDuration: Double = 15
    @State private var pomodorosUntilLongBreak: Int = 4
    @State private var soundEnabled: Bool = true
    @State private var autoStartBreaks: Bool = false
    @State private var focusSound: PomodoroSound = .ticking
    @State private var shortBreakSound: PomodoroSound = .rain
    @State private var longBreakSound: PomodoroSound = .forest
    @State private var volume: Double = 0.5
    
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
                        durationSection
                        behaviorSection
                        soundSection
                        keyboardSection
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 360, height: 620)
        .onAppear(perform: loadSettings)
        .onChange(of: workDuration) { newValue in
            UserDefaults.standard.set(newValue, forKey: "workDuration")
        }
        .onChange(of: shortBreakDuration) { newValue in
            UserDefaults.standard.set(newValue, forKey: "shortBreakDuration")
        }
        .onChange(of: longBreakDuration) { newValue in
            UserDefaults.standard.set(newValue, forKey: "longBreakDuration")
        }
        .onChange(of: pomodorosUntilLongBreak) { newValue in
            UserDefaults.standard.set(newValue, forKey: "pomodorosUntilLongBreak")
        }
        .onChange(of: autoStartBreaks) { newValue in
            UserDefaults.standard.set(newValue, forKey: "autoStartBreaks")
        }
        .onChange(of: soundEnabled) { newValue in
            UserDefaults.standard.set(newValue, forKey: "soundEnabled")
            AudioManager.shared.enabled = newValue
            if !newValue {
                AudioManager.shared.stop()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(primaryText)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(secondaryText)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(cardBackground)
    }
    
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Durations", icon: "clock.fill", color: .blue)
            
            VStack(spacing: 10) {
                DurationSliderRow(
                    title: "Focus Time",
                    icon: "brain.head.profile",
                    color: TimerMode.work.color(for: theme),
                    value: $workDuration,
                    range: 5...60,
                    step: 5,
                    primaryText: primaryText
                )
                
                DurationSliderRow(
                    title: "Short Break",
                    icon: "leaf.fill",
                    color: TimerMode.shortBreak.color(for: theme),
                    value: $shortBreakDuration,
                    range: 1...15,
                    step: 1,
                    primaryText: primaryText
                )
                
                DurationSliderRow(
                    title: "Long Break",
                    icon: "moon.fill",
                    color: TimerMode.longBreak.color(for: theme),
                    value: $longBreakDuration,
                    range: 10...30,
                    step: 5,
                    primaryText: primaryText
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "target")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("Pomodoros until long break")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(primaryText)
                        Spacer()
                        Text("\(pomodorosUntilLongBreak)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .monospacedDigit()
                    }
                    Slider(
                        value: Binding(
                            get: { Double(pomodorosUntilLongBreak) },
                            set: { pomodorosUntilLongBreak = Int($0) }
                        ),
                        in: 2...8,
                        step: 1
                    )
                    .accentColor(.orange)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardBackground)
                )
            }
        }
    }
    
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Behavior", icon: "slider.horizontal.3", color: .purple)
            
            VStack(spacing: 8) {
                ToggleRow(
                    title: "Auto-start Breaks",
                    subtitle: "Automatically start break timer",
                    icon: "play.circle.fill",
                    color: .green,
                    isOn: $autoStartBreaks,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    cardBackground: cardBackground
                )
                
                Divider().background(secondaryText.opacity(0.2))
                
                ToggleRow(
                    title: "Sound Effects",
                    subtitle: "Enable ambient sounds",
                    icon: "speaker.wave.2.fill",
                    color: .blue,
                    isOn: $soundEnabled,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    cardBackground: cardBackground
                )
                
                if soundEnabled {
                    Divider().background(secondaryText.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            Text("Volume")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(primaryText)
                            Spacer()
                            Text("\(Int(volume * 100))%")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(primaryText)
                                .monospacedDigit()
                        }
                        Slider(value: $volume, in: 0...1)
                            .accentColor(.blue)
                            .onChange(of: volume) { newValue in
                                AudioManager.shared.setVolume(Float(newValue))
                            }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackground)
            )
        }
    }
    
    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Sounds", icon: "music.note", color: .pink)
            
            VStack(spacing: 10) {
                SoundPickerRow(
                    title: "Focus",
                    icon: "brain",
                    color: TimerMode.work.color(for: theme),
                    selection: $focusSound,
                    defaultsKey: "focusSound",
                    primaryText: primaryText,
                    cardBackground: cardBackground
                )
                
                SoundPickerRow(
                    title: "Short Break",
                    icon: "leaf",
                    color: TimerMode.shortBreak.color(for: theme),
                    selection: $shortBreakSound,
                    defaultsKey: "shortBreakSound",
                    primaryText: primaryText,
                    cardBackground: cardBackground
                )
                
                SoundPickerRow(
                    title: "Long Break",
                    icon: "moon",
                    color: TimerMode.longBreak.color(for: theme),
                    selection: $longBreakSound,
                    defaultsKey: "longBreakSound",
                    primaryText: primaryText,
                    cardBackground: cardBackground
                )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackground)
            )
        }
    }
    
    private var keyboardSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "keyboard")
                .font(.system(size: 12))
                .foregroundColor(secondaryText)
            Text("Shortcuts:")
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
            Text("Space")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(secondaryText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(cardBackground))
            Text("⌘R")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(secondaryText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(cardBackground))
            Text("⌘S")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(secondaryText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(cardBackground))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cardBackground.opacity(0.5))
        )
    }
    
    private func loadSettings() {
        workDuration = UserDefaults.standard.double(forKey: "workDuration")
        shortBreakDuration = UserDefaults.standard.double(forKey: "shortBreakDuration")
        longBreakDuration = UserDefaults.standard.double(forKey: "longBreakDuration")
        pomodorosUntilLongBreak = UserDefaults.standard.integer(forKey: "pomodorosUntilLongBreak")
        autoStartBreaks = UserDefaults.standard.bool(forKey: "autoStartBreaks")
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        AudioManager.shared.enabled = soundEnabled
        
        // Load saved sounds
        if let focusRaw = UserDefaults.standard.string(forKey: "focusSound"),
           let focus = PomodoroSound(rawValue: focusRaw) {
            focusSound = focus
        }
        if let shortRaw = UserDefaults.standard.string(forKey: "shortBreakSound"),
           let short = PomodoroSound(rawValue: shortRaw) {
            shortBreakSound = short
        }
        if let longRaw = UserDefaults.standard.string(forKey: "longBreakSound"),
           let long = PomodoroSound(rawValue: longRaw) {
            longBreakSound = long
        }
        
        if pomodorosUntilLongBreak == 0 { pomodorosUntilLongBreak = 4 }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct DurationSliderRow: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let primaryText: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryText)
                Spacer()
                Text("\(Int(value)) min")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(primaryText)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
                .accentColor(color)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    let primaryText: Color
    let secondaryText: Color
    let cardBackground: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryText)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(secondaryText)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
    }
}

struct SoundPickerRow: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var selection: PomodoroSound
    let defaultsKey: String
    let primaryText: Color
    let cardBackground: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(primaryText.opacity(0.8))
            }
            
            HStack(spacing: 4) {
                ForEach([PomodoroSound.ticking, .rain, .forest, .ocean, .cafe], id: \.self) { sound in
                    Button(action: {
                        selection = sound
                        UserDefaults.standard.set(sound.rawValue, forKey: defaultsKey)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: sound.icon)
                                .font(.system(size: 9))
                            Text(sound.shortName)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selection == sound ? .white : primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selection == sound ? color : cardBackground)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

#Preview {
    SettingsView(timer: PomodoroTimer())
}
