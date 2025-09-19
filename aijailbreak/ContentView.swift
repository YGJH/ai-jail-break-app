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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // App 圖標和標題
                VStack(spacing: 20) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .symbolEffect(.pulse)
                    
                    VStack(spacing: 8) {
                        Text("AI Jailbreak")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("挑戰 AI 的邊界")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 遊戲描述
                VStack(spacing: 12) {
                    Text("歡迎來到 AI Jailbreak 挑戰！")
                        .font(.headline)
                    
                    Text("在這個遊戲中，你需要使用創意和技巧來說服 AI 說出特定的內容。每個關卡都有不同的挑戰目標和難度等級。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 操作按鈕
                VStack(spacing: 16) {
                    Button(action: {
                        soundManager.playButtonTap()
                        showingGame = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("開始遊戲")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        soundManager.playButtonTap()
                        showingSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("設置")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 底部說明
                Text("⚠️ 本遊戲僅供教育和娛樂目的")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationBarHidden(true)
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
