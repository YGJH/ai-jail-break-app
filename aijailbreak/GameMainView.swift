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
    @Query private var gameProgress: [GameProgress]
    @State private var selectedLevel: GameLevel?
    @State private var showingLevelDetail = false
    
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
            ScrollView {
                VStack(spacing: 20) {
                    // 遊戲標題和說明
                    VStack(spacing: 10) {
                        Text("AI Jailbreak 挑戰")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("挑戰你的說服技巧，讓 AI 說出你想要的話！")
                            .font(Font.title3.monospaced())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // 遊戲統計
                    GameStatsView(progress: progress)

                    // Prompt 強度選擇
                    PromptStrengthPicker()
                    
                    // 關卡列表
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        ForEach(GameLevels.allLevels) { level in
                            LevelCardView(
                                level: level,
                                isUnlocked: GameLevels.isUnlocked(level: level, progress: progress),
                                isCompleted: progress.completedLevels.contains(level.id)
                            ) {
                                selectedLevel = level
                                showingLevelDetail = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("AI Jailbreak")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingLevelDetail) {
                if let level = selectedLevel {
                    GameChatView(level: level, progress: progress)
                }
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

#Preview {
    GameMainView()
        .modelContainer(for: GameProgress.self, inMemory: true)
}
