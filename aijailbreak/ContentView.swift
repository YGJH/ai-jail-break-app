//
//  ContentView.swift
//  aijailbreak
//
//  Created by user20 on 2025/9/19.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingGame = false
    @State private var showingSettings = false
    @StateObject private var soundManager = SoundManager.shared
    @State private var animateGradient = false
    @State private var pulseScale = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // 黑色後備底色，避免出現白色邊緣
                Color.black
                    .ignoresSafeArea()

                // 動態漸變背景 - 使用 GeometryReader 確保其尺寸至少覆蓋螢幕的對角線
                GeometryReader { geo in
                    let diagonal = sqrt(geo.size.width * geo.size.width + geo.size.height * geo.size.height)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.05, green: 0.05, blue: 0.15),
                            Color(red: 0.1, green: 0.1, blue: 0.3),
                            Color(red: 0.05, green: 0.15, blue: 0.25),
                            Color(red: 0.0, green: 0.0, blue: 0.1)
                        ]),
                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                    )
                    .frame(width: .infinity, height: .infinity)
                }
                
                // 背景粒子效果（已停用）
                ParticleField() 

                // 固定背景圖片（用來遮蓋變動漸變導致的角落缺口）
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App 圖標和標題
                    VStack(spacing: 20) {
                        ZStack {
                            // 外圈光暈
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.cyan.opacity(0.4), Color.clear],
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)
                                .scaleEffect(pulseScale)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseScale)
                            
                            // 主圖標
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 80, weight: .ultraLight))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
                        }
                        
                        VStack(spacing: 12) {
                            Text("AI JAILBREAK")
                                .font(.system(size: 32, weight: .black, design: .monospaced))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.cyan, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.cyan.opacity(0.5), radius: 10, x: 0, y: 0)
                            
                            Text("挑戰 AI 的邊界")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.cyan.opacity(0.8))
                                .textCase(.uppercase)
                                .tracking(2)
                        }
                    }
                    
                    // 遊戲描述卡片
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.cyan)
                            Text("歡迎來到 AI Jailbreak 挑戰！")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("在這個遊戲中，你需要使用創意和技巧來說服 AI 說出特定的內容。每個關卡都有不同的挑戰目標和難度等級。")
                            .font(.body)
                            .foregroundColor(Color.gray.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // 現代化操作按鈕
                    VStack(spacing: 20) {
                        ModernButton(
                            title: "開始遊戲",
                            icon: "play.fill",
                            colors: [Color.cyan, Color.blue],
                            action: {
                                soundManager.playButtonTap()
                                showingGame = true
                            }
                        )
                        
                        ModernButton(
                            title: "設置",
                            icon: "gearshape.fill",
                            colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)],
                            isSecondary: true,
                            action: {
                                soundManager.playButtonTap()
                                showingSettings = true
                            }
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // 底部說明
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("本遊戲僅供教育和娛樂目的")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom)
                }
            }
            .clipped()  // 防止任何內容超出螢幕邊界
            .navigationBarHidden(true)
            .onAppear {
                animateGradient = true
                pulseScale = 1.1
            }
        }
        .fullScreenCover(isPresented: $showingGame) {
            GameMainView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var gameProgress: [GameProgress]
    @State private var showingAPIConfig = false
    
    var body: some View {
        NavigationView {
            List {
                Section("遊戲設置") {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("AI 模型")
                        Spacer()
                        Text("Gemini 1.5 Flash")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showingAPIConfig = true
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("API 設置")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section("遊戲數據") {
                    if let progress = gameProgress.first {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("總分")
                            Spacer()
                            Text("\(progress.totalScore)")
                                .foregroundColor(.orange)
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("已完成關卡")
                            Spacer()
                            Text("\(progress.completedLevels.count)")
                                .foregroundColor(.green)
                        }
                        
                        Button(action: resetGameData) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("重置遊戲數據")
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Text("尚無遊戲數據")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("關於") {
                    HStack {
                        Image(systemName: "info.circle.fill")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Jailbreak")
                                .fontWeight(.semibold)
                            Text("版本 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                            Text("遊戲說明")
                        }
                        
                        Text("這是一個教育性的遊戲，旨在幫助用戶了解 AI 系統的限制和安全機制。請負責任地使用。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAPIConfig) {
                APIConfigView()
            }
        }
    }
    
    private func resetGameData() {
        for progress in gameProgress {
            modelContext.delete(progress)
        }
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: GameProgress.self, inMemory: true)
}

// 現代化按鈕組件
struct ModernButton: View {
    let title: String
    let icon: String
    let colors: [Color]
    var isSecondary: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .foregroundColor(isSecondary ? .white : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    if isSecondary {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: colors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: colors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: colors.first?.opacity(0.4) ?? .clear,
                radius: isPressed ? 5 : 10,
                x: 0,
                y: isPressed ? 2 : 5
            )
        }
    }
}

// 粒子場效果
struct ParticleField: View {
    @State private var particles: [MovingParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: 3)  // 進一步增加模糊半徑
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()  // 防止粒子繪製到視圖邊界外
            .onAppear {
                createParticles(in: geometry.size)
                startAnimation(in: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                createParticles(in: newSize)
            }
        }
        .ignoresSafeArea()  // 確保粒子場覆蓋整個螢幕
    }
    
    private func createParticles(in size: CGSize) {
        particles = []
        for _ in 0..<20 {  // 進一步減少粒子數量
            let particle = MovingParticle(
                id: UUID(),
                position: CGPoint(
                    x: Double.random(in: 0...size.width),
                    y: Double.random(in: 0...size.height)
                ),
                velocity: CGPoint(
                    x: Double.random(in: -0.2...0.2),  // 進一步減慢水平移動
                    y: Double.random(in: -0.5 ... -0.1)  // 進一步減慢垂直移動
                ),
                color: [Color.cyan, Color.blue, Color.purple, Color.white].randomElement()?.opacity(0.2) ?? Color.cyan.opacity(0.2),
                size: Double.random(in: 4...10),  // 進一步增加粒子大小
                opacity: Double.random(in: 0.05...0.3)  // 進一步降低不透明度
            )
            particles.append(particle)
        }
    }
    
    private func startAnimation(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { _ in  // 增加更新頻率使動畫更流暢
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                
                // 更保守的重置邏輯，使用更大的緩衝區
                if particles[i].position.y < -30 {
                    particles[i].position.y = size.height + 30
                    particles[i].position.x = Double.random(in: 0...size.width)
                }
                if particles[i].position.x < -30 {
                    particles[i].position.x = size.width + 30
                }
                if particles[i].position.x > size.width + 30 {
                    particles[i].position.x = -30
                }
            }
        }
    }
}

struct MovingParticle {
    let id: UUID
    var position: CGPoint
    let velocity: CGPoint
    let color: Color
    let size: Double
    let opacity: Double
}
