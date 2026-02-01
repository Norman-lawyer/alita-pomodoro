import SwiftUI
import Combine
import AppKit

struct ContentView: View {
    @ObservedObject var timer: PomodoroTimer
    @State private var showingSettings = false
    @State private var showingStats = false
    @State private var animatePulse = false
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                headerSection
                Spacer()
                timerSection
                Spacer()
                modeSelector
                Spacer()
                controlSection
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .frame(width: 340, height: 520)
        .sheet(isPresented: $showingSettings) {
            SettingsView(timer: timer)
        }
        .sheet(isPresented: $showingStats) {
            StatsView(timer: timer)
        }
        .onChange(of: timer.state) { newState in
            if newState == .complete {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    animatePulse = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    animatePulse = false
                }
            }
        }
    }
    
    private var backgroundGradient: LinearGradient {
        let colors: [Color] = {
            switch timer.theme {
            case .dark:
                return [
                    timer.currentMode.color(for: .dark).opacity(0.8),
                    Color(red: 0.08, green: 0.08, blue: 0.10).opacity(0.95),
                    Color(red: 0.06, green: 0.06, blue: 0.08)
                ]
            case .light:
                return [
                    timer.currentMode.color(for: .light).opacity(0.6),
                    Color(red: 0.96, green: 0.96, blue: 0.98),
                    Color(red: 0.92, green: 0.92, blue: 0.94)
                ]
            }
        }()
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var primaryText: Color {
        timer.theme.primaryTextColor
    }
    
    private var secondaryText: Color {
        timer.theme.secondaryTextColor
    }
    
    private var cardBackground: Color {
        timer.theme.cardBackgroundColor
    }
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            // 统计按钮 - 番茄数
            Button(action: { showingStats = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("\(timer.todayPomodoros)")
                        .font(.system(size: 11, weight: .bold))
                        .monospacedDigit()
                }
                .foregroundColor(primaryText.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(cardBackground)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // 功能按钮组
            HStack(spacing: 8) {
                // 主题切换
                Button(action: {
                    timer.theme = timer.theme == .dark ? .light : .dark
                }) {
                    Image(systemName: timer.theme.icon)
                        .font(.system(size: 12))
                        .foregroundColor(timer.theme == .dark ? .white : Color(red: 0.9, green: 0.7, blue: 0.2))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(timer.theme == .dark ? Color.white.opacity(0.1) : Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.15))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 设置
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(cardBackground)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var timerSection: some View {
        ZStack {
            Circle()
                .fill(timer.currentMode.color(for: timer.theme).opacity(animatePulse ? 0.3 : 0.1))
                .frame(width: 220, height: 220)
                .blur(radius: animatePulse ? 30 : 15)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animatePulse)
            
            Circle()
                .stroke(timer.theme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 8)
                .frame(width: 200, height: 200)
            
            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(
                    timer.currentMode.color(for: timer.theme),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: timer.progress)
            
            Circle()
                .fill(timer.theme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color(red: 0.94, green: 0.94, blue: 0.96))
                .frame(width: 180, height: 180)
            
            VStack(spacing: 8) {
                Text(timer.stateDisplay)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(timer.currentMode.color(for: timer.theme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(timer.currentMode.color(for: timer.theme).opacity(0.15))
                    )
                
                Text(timer.formattedTime)
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundColor(primaryText)
                    .monospacedDigit()
                    .shadow(color: timer.theme == .dark ? .black.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
            }
        }
    }
    
    private var modeSelector: some View {
        HStack(spacing: 6) {
            ForEach([TimerMode.work, .shortBreak, .longBreak], id: \.self) { mode in
                ModeButton(
                    mode: mode,
                    theme: timer.theme,
                    isSelected: timer.currentMode == mode,
                    action: { timer.setMode(mode) }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
        )
    }
    
    private var controlSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                timer.reset()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(secondaryText)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardBackground)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(timer.state == .idle ? 0.3 : 1)
            .disabled(timer.state == .idle)
            
            Button(action: {
                playPause()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 14, weight: .semibold))
                    Text(buttonTitle)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(timer.currentMode.color(for: timer.theme))
                        .shadow(color: timer.currentMode.color(for: timer.theme).opacity(0.4), radius: 10, x: 0, y: 5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                timer.skip()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(secondaryText)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardBackground)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(timer.state == .idle ? 0.3 : 1)
            .disabled(timer.state == .idle)
        }
    }
    
    private func playPause() {
        switch timer.state {
        case .idle: timer.start()
        case .running: timer.pause()
        case .paused: timer.resume()
        default: break
        }
    }
    
    private var buttonIcon: String {
        switch timer.state {
        case .idle: return "play.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        case .complete: return "play.fill"
        }
    }
    
    private var buttonTitle: String {
        switch timer.state {
        case .idle: return "Start"
        case .running: return "Pause"
        case .paused: return "Resume"
        case .complete: return "Start"
        }
    }
}

// MARK: - Supporting Views

struct ModeButton: View {
    let mode: TimerMode
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    private var textColor: Color {
        isSelected ? mode.color(for: theme) : theme.secondaryTextColor
    }
    
    var body: some View {
        Button(action: {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(textColor)
                
                Text(mode.shortTitle)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? mode.color(for: theme).opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView(timer: PomodoroTimer())
        .frame(width: 340, height: 520)
}
