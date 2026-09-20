//
//  SoundManager.swift
//  ChemistryCoach
//
//  Tiny, dependency-free sound-effects layer used throughout the app for
//  answer feedback, stage transitions, and readings taken in the virtual
//  labs. Deliberately simple: five short, synthesized tones bundled under
//  Resources/Sounds, preloaded once, played through a small pool of
//  `AVAudioPlayer`s. The `.ambient` audio session category means these
//  effects mix with any other audio the student has playing and are
//  silenced by the ringer/silent switch, matching how system UI sounds
//  behave rather than fighting for foreground audio.
//
//  Respects a persisted "sound effects" toggle (surfaced in Settings) so
//  students can turn feedback sounds off entirely.
//

import AVFoundation

enum SoundEffect: String, CaseIterable {
    /// Light UI taps — selecting an option, revealing an answer, moving
    /// between workflow stages.
    case tap
    /// Correct answer / correct apparatus reading / passed a stage.
    case success
    /// Incorrect answer / wrong apparatus reading.
    case error
    /// Finishing a whole experiment or quiz.
    case complete
    /// Taking a reading/measurement (stopwatch tick, burette meniscus,
    /// balance settling) in a virtual lab.
    case measurement
}

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private enum Keys {
        static let enabled = "sound_effects_enabled"
    }

    private let defaults: UserDefaults
    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var sessionConfigured = false

    /// Whether sound effects are enabled. Defaults to `true` on first
    /// launch; persisted across sessions via `UserDefaults`.
    var isEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.enabled) == nil { return true }
            return defaults.bool(forKey: Keys.enabled)
        }
        set { defaults.set(newValue, forKey: Keys.enabled) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        preloadPlayers()
    }

    private func preloadPlayers() {
        for effect in SoundEffect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav", subdirectory: nil)
                ?? Bundle.main.url(forResource: effect.rawValue, withExtension: "wav", subdirectory: "Sounds")
            else { continue }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[effect] = player
            }
        }
    }

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// Plays the given effect if sound effects are enabled. Safe to call
    /// from any view/view-model — no-ops silently if the asset is missing
    /// or playback is disabled.
    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }
        guard let player = players[effect] else { return }
        configureSessionIfNeeded()
        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }
}
