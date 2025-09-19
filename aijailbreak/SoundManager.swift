//
//  SoundManager.swift
//  aijailbreak
//
//  Created by Assistant on 2025/9/19.
//

import Foundation
import AVFoundation
import Combine

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    @Published var isSoundEnabled = true
    
    // Sound types
    enum SoundType: String, CaseIterable {
        case buttonTap = "button_tap"
        case success = "success"
        case failure = "failure"
        case messageSend = "message_send"
        case messageReceive = "message_receive"
        case levelUnlock = "level_unlock"
        case hint = "hint"
        case warning = "warning"
        case tick = "tick"
        case swoosh = "swoosh"
    }
    
    private init() {
        loadSoundSettings()
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func loadSoundSettings() {
        isSoundEnabled = UserDefaults.standard.bool(forKey: "sound_enabled")
        // Default to true if not set
        if UserDefaults.standard.object(forKey: "sound_enabled") == nil {
            isSoundEnabled = true
            UserDefaults.standard.set(true, forKey: "sound_enabled")
        }
    }
    
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "sound_enabled")
    }
    
    private func preloadSounds() {
        // For now, we'll use system sounds and generate simple tones
        // In a real app, you would load actual sound files
        for soundType in SoundType.allCases {
            createSystemSound(for: soundType)
        }
    }
    
    private func createSystemSound(for soundType: SoundType) {
        // Create simple programmatic sounds since we don't have audio files
        let player = createTonePlayer(for: soundType)
        audioPlayers[soundType.rawValue] = player
    }
    
    private func createTonePlayer(for soundType: SoundType) -> AVAudioPlayer? {
        // Generate simple tone data based on sound type
        let (frequency, duration) = getToneProperties(for: soundType)
        
        guard let audioData = generateTone(frequency: frequency, duration: duration) else {
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(data: audioData)
            player.prepareToPlay()
            return player
        } catch {
            print("Failed to create audio player for \(soundType): \(error)")
            return nil
        }
    }
    
    private func getToneProperties(for soundType: SoundType) -> (frequency: Double, duration: Double) {
        switch soundType {
        case .buttonTap:
            return (800, 0.1)
        case .success:
            return (523, 0.3) // C note
        case .failure:
            return (196, 0.5) // G note (lower)
        case .messageSend:
            return (660, 0.15) // E note
        case .messageReceive:
            return (440, 0.2) // A note
        case .levelUnlock:
            return (659, 0.4) // E note (higher)
        case .hint:
            return (880, 0.25) // A note (higher)
        case .warning:
            return (233, 0.3) // Bb note (low)
        case .tick:
            return (1000, 0.05)
        case .swoosh:
            return (200, 0.2)
        }
    }
    
    private func generateTone(frequency: Double, duration: Double) -> Data? {
        let sampleRate = 44100.0
        let samples = Int(sampleRate * duration)
        var audioData = Data()
        
        for i in 0..<samples {
            let time = Double(i) / sampleRate
            let amplitude = sin(2.0 * Double.pi * frequency * time)
            let sample = Int16(amplitude * 32767.0 * 0.3) // 30% volume
            
            withUnsafeBytes(of: sample.littleEndian) { bytes in
                audioData.append(contentsOf: bytes)
            }
        }
        
        // Create WAV header
        let wavHeader = createWAVHeader(dataSize: audioData.count, sampleRate: Int(sampleRate))
        var wavData = wavHeader
        wavData.append(audioData)
        
        return wavData
    }
    
    private func createWAVHeader(dataSize: Int, sampleRate: Int) -> Data {
        var header = Data()
        
        // RIFF header
        header.append("RIFF".data(using: .ascii)!)
        header.append(UInt32(dataSize + 36).littleEndianData)
        header.append("WAVE".data(using: .ascii)!)
        
        // Format chunk
        header.append("fmt ".data(using: .ascii)!)
        header.append(UInt32(16).littleEndianData) // Format chunk size
        header.append(UInt16(1).littleEndianData)  // PCM format
        header.append(UInt16(1).littleEndianData)  // Mono
        header.append(UInt32(sampleRate).littleEndianData)
        header.append(UInt32(sampleRate * 2).littleEndianData) // Byte rate
        header.append(UInt16(2).littleEndianData)  // Block align
        header.append(UInt16(16).littleEndianData) // Bits per sample
        
        // Data chunk
        header.append("data".data(using: .ascii)!)
        header.append(UInt32(dataSize).littleEndianData)
        
        return header
    }
    
    func playSound(_ soundType: SoundType) {
        guard isSoundEnabled else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let player = self.audioPlayers[soundType.rawValue] else {
                return
            }
            
            player.stop()
            player.currentTime = 0
            player.play()
        }
    }
    
    // Convenience methods for common sounds
    func playButtonTap() { playSound(.buttonTap) }
    func playSuccess() { playSound(.success) }
    func playFailure() { playSound(.failure) }
    func playMessageSend() { playSound(.messageSend) }
    func playMessageReceive() { playSound(.messageReceive) }
    func playLevelUnlock() { playSound(.levelUnlock) }
    func playHint() { playSound(.hint) }
    func playWarning() { playSound(.warning) }
    func playTick() { playSound(.tick) }
    func playSwoosh() { playSound(.swoosh) }
}

extension UInt32 {
    var littleEndianData: Data {
        var value = self.littleEndian
        return withUnsafeBytes(of: &value) { Data($0) }
    }
}

extension UInt16 {
    var littleEndianData: Data {
        var value = self.littleEndian
        return withUnsafeBytes(of: &value) { Data($0) }
    }
}
