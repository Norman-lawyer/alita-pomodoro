import Foundation
import AVFoundation

enum PomodoroSound: String, CaseIterable {
    case ticking = "Ticking"
    case rain = "Rain"
    case forest = "Forest"
    case ocean = "Ocean"
    case cafe = "Cafe"
    
    var displayName: String { rawValue }
    var shortName: String {
        switch self {
        case .ticking: return "Clock"
        case .rain: return "Rain"
        case .forest: return "Forest"
        case .ocean: return "Ocean"
        case .cafe: return "Cafe"
        }
    }
    var icon: String {
        switch self {
        case .ticking: return "clock.fill"
        case .rain: return "cloud.rain.fill"
        case .forest: return "tree.fill"
        case .ocean: return "waveform"
        case .cafe: return "cup.and.saucer.fill"
        }
    }
    
    var fileName: String {
        switch self {
        case .ticking: return "ticking"
        case .rain: return "rain"
        case .forest: return "forest"
        case .ocean: return "ocean"
        case .cafe: return "cafe"
        }
    }
}

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published var isPlaying = false
    @Published var currentSound: PomodoroSound = .ticking
    @Published var volume: Float = 0.5
    @Published var enabled = true
    
    private var ambientPlayer: AVAudioPlayer?
    private var tickingPlayer: AVAudioPlayer?
    private var tickingTimer: Timer?
    
    func play(_ sound: PomodoroSound) {
        guard enabled else {
            stop()
            return
        }
        
        currentSound = sound
        stop()
        
        if sound == .ticking {
            startTicking()
        } else {
            startAmbient(sound: sound)
        }
    }
    
    func stop() {
        tickingTimer?.invalidate()
        tickingTimer = nil
        ambientPlayer?.stop()
        tickingPlayer?.stop()
        isPlaying = false
    }
    
    func setVolume(_ value: Float) {
        volume = max(0, min(1, value))
        ambientPlayer?.volume = volume
        tickingPlayer?.volume = volume
    }
    
    // MARK: - Ticking Sound (每秒播放一次)
    
    private func startTicking() {
        if let url = Bundle.main.url(forResource: "ticking", withExtension: "wav") {
            do {
                tickingPlayer = try AVAudioPlayer(contentsOf: url)
                tickingPlayer?.volume = volume
                tickingPlayer?.prepareToPlay()
            } catch {
                print("Failed to load ticking sound: \(error)")
            }
        }
        
        // 每秒播放一次滴答声
        tickingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.playTick()
        }
        
        playTick()
        isPlaying = true
    }
    
    private func playTick() {
        tickingPlayer?.currentTime = 0
        tickingPlayer?.play()
    }
    
    // MARK: - Ambient Sounds from Files
    
    private func startAmbient(sound: PomodoroSound) {
        let fileName = sound.fileName
        
        // Try .ogg first, then .mp3, then .caf
        let extensions = ["ogg", "mp3", "caf"]
        var found = false
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                do {
                    ambientPlayer = try AVAudioPlayer(contentsOf: url)
                    ambientPlayer?.volume = volume * 0.6
                    ambientPlayer?.numberOfLoops = -1 // Loop forever
                    ambientPlayer?.play()
                    isPlaying = true
                    print("✅ Playing: \(fileName).\(ext)")
                    found = true
                    break
                } catch {
                    print("❌ Failed to load '\(fileName).\(ext)': \(error)")
                }
            }
        }
        
        if !found {
            print("⚠️ Sound file not found for: \(fileName)")
        }
    }
}
