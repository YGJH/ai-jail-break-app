//
//  GameMainView.swift
//  aijailbreak
//
//  Created by user20 on 2025/9/19.
//

import SwiftUI
import SwiftData

struct GameMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var gameProgress: [GameProgress]
    @State private var selectedLevel: GameLevel?
    @StateObject private var soundManager = SoundManager.shared
    
    private var progress: GameProgress {
        if let existingProgress = gameProgress.first {
            return existingProgress
        } else {
            let newProgress = GameProgress()
            modelContext.insert(newProgress)
            // Save immediately so that @Query observes the new object and UI updates.
            do {
                try modelContext.save()
            } catch {
                // silently ignore save errors for now
            }
            return newProgress
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 科技感背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.05, green: 0.15, blue: 0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 遊戲標題和統計
                        VStack(spacing: 20) {
                            VStack(spacing: 10) {
                                Text("AI JAILBREAK")
                                    .font(.system(size: 28, weight: .black, design: .monospaced))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.cyan, Color.blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .textCase(.uppercase)
                                    .tracking(2)
                                
                                Text("挑戰你的說服技巧")
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.cyan.opacity(0.8))
                                    .textCase(.uppercase)
                                    .tracking(1)
                            }
                            
                            // 現代化統計卡片
                            ModernStatsView(progress: progress)
                            
                            // Prompt 強度選擇
                            ModernPromptStrengthPicker()
                        }
                        .padding(.top)
                        
                        // 關卡網格
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 20) {
                            ForEach(GameLevels.allLevels) { level in
                                ModernLevelCard(
                                    level: level,
                                    isUnlocked: GameLevels.isUnlocked(level: level, progress: progress),
                                    isCompleted: progress.completedLevels.contains(level.id),
                                    action: {
                                        soundManager.playButtonTap()
                                        selectedLevel = level
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("AI Jailbreak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        soundManager.playButtonTap()
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
            .sheet(item: $selectedLevel) { level in
                GameChatView(level: level, progress: progress)
            }
        }
    }
}

struct GameStatsView: View {
    let progress: GameProgress
    
    var body: some View {
        HStack(spacing: 30) {
            StatItem(
                title: "總分",
                value: "\(progress.totalScore)",
                icon: "star.fill",
                color: .orange
            )
            
            StatItem(
                title: "已完成",
                value: "\(progress.completedLevels.count)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatItem(
                title: "已解鎖",
                value: "\(progress.unlockedLevels.count)",
                icon: "lock.open.fill",
                color: .blue
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct LevelCardView: View {
    let level: GameLevel
    let isUnlocked: Bool
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: isUnlocked ? onTap : {}) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("第 \(level.id) 關")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(level.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(level.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    DifficultyBadge(difficulty: level.difficulty)
                    
                    Spacer()
                    
                    Text("\(level.scoreReward) 分")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isUnlocked ? Color(.systemBackground) : Color(.systemGray5))
                    .shadow(color: .black.opacity(isUnlocked ? 0.1 : 0.05), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCompleted ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!isUnlocked)
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty
    
    private var color: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        case .expert: return .purple
        }
    }
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(6)
    }
}

struct PromptStrengthPicker: View {
    @AppStorage("prompt_strength") private var strength: String = "strong"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("系統提示強度")
                .font(.subheadline)
                .fontWeight(.semibold)

            Picker("強度", selection: $strength) {
                Text("強").tag("strong")
                Text("弱").tag("weak")
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }
}

// 現代化統計視圖
struct ModernStatsView: View {
    let progress: GameProgress
    
    var body: some View {
        HStack(spacing: 20) {
            ModernStatCard(
                title: "總分",
                value: "\(progress.totalScore)",
                icon: "star.fill",
                colors: [Color.orange, Color.yellow]
            )
            
            ModernStatCard(
                title: "已完成",
                value: "\(progress.completedLevels.count)",
                icon: "checkmark.circle.fill",
                colors: [Color.green, Color.mint]
            )
            
            ModernStatCard(
                title: "解鎖關卡",
                value: "\(progress.unlockedLevels.count)",
                icon: "lock.open.fill",
                colors: [Color.blue, Color.cyan]
            )
        }
        .padding(.horizontal)
    }
}

struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let colors: [Color]
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: colors.map { $0.opacity(0.6) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// 現代化 Prompt 強度選擇器
struct ModernPromptStrengthPicker: View {
    @AppStorage("prompt_strength") private var strength: String = "strong"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.cyan)
                Text("系統提示強度")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            
            HStack(spacing: 12) {
                ForEach(["strong", "weak"], id: \.self) { option in
                    Button(action: {
                        strength = option
                    }) {
                        HStack {
                            Image(systemName: strength == option ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(strength == option ? .cyan : .gray)
                            Text(option == "strong" ? "強" : "弱")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(strength == option ? .white : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(strength == option ? Color.cyan.opacity(0.2) : Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            strength == option ? Color.cyan : Color.gray.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// 現代化關卡卡片
struct ModernLevelCard: View {
    let level: GameLevel
    let isUnlocked: Bool
    let isCompleted: Bool
    let action: () -> Void
    
    private var cardColors: [Color] {
        if isCompleted {
            return [Color.green.opacity(0.3), Color.mint.opacity(0.3)]
        } else if isUnlocked {
            return [Color.blue.opacity(0.3), Color.cyan.opacity(0.3)]
        } else {
            return [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]
        }
    }
    
    private var borderColors: [Color] {
        if isCompleted {
            return [Color.green, Color.mint]
        } else if isUnlocked {
            return [Color.cyan, Color.blue]
        } else {
            return [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // 關卡標題和圖標
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("關卡 \(level.id)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(isUnlocked ? .cyan : .gray)
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        Text(level.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isUnlocked ? .white : .gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: cardColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: isCompleted ? "checkmark" : (isUnlocked ? "play.fill" : "lock.fill"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isUnlocked ? .white : .gray)
                    }
                }
                
                // 關卡描述
                Text(level.description)
                    .font(.system(size: 12))
                    .foregroundColor(isUnlocked ? .gray : .gray.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 難度和分數
                HStack {
                    ModernDifficultyBadge(difficulty: level.difficulty, isUnlocked: isUnlocked)
                    
                    Spacer()
                    
                    if isUnlocked {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("\(level.scoreReward)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(16)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: cardColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: borderColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isUnlocked ? Color.cyan.opacity(0.3) : Color.clear,
                radius: isUnlocked ? 8 : 0,
                x: 0,
                y: 4
            )
            .scaleEffect(isUnlocked ? 1.0 : 0.95)
        }
        .disabled(!isUnlocked)
    }
}

struct ModernDifficultyBadge: View {
    let difficulty: Difficulty
    let isUnlocked: Bool
    
    private var colors: [Color] {
        guard isUnlocked else { return [.gray, .gray] }
        
        switch difficulty {
        case .easy: return [.green, .mint]
        case .medium: return [.orange, .yellow]
        case .hard: return [.red, .pink]
        case .expert: return [.purple, .indigo]
        }
    }
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(6)
    }
}

#Preview {
    GameMainView()
        .modelContainer(for: GameProgress.self, inMemory: true)
}
