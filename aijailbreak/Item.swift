//
//  GameModels.swift
//  aijailbreak
//
//  Created by user20 on 2025/9/19.
//

import Foundation
import SwiftData

// 遊戲進度模型
@Model
final class GameProgress {
    var unlockedLevels: [Int]
    var completedLevels: [Int]
    var lastPlayedLevel: Int
    var totalScore: Int
    
    init() {
        self.unlockedLevels = [1] // 第一關默認解鎖
        self.completedLevels = []
        self.lastPlayedLevel = 1
        self.totalScore = 0
    }
}

// 關卡難度
enum Difficulty: String, CaseIterable {
    case easy = "簡單"
    case medium = "中等"
    case hard = "困難"
    case expert = "專家"
}

// 挑戰類型
enum ChallengeType: String, CaseIterable {
    case makeAISayWord = "讓AI說出特定詞語"
    case makeAIGiveBadAdvice = "讓AI給出不當建議" 
    case makeAIRoleplay = "讓AI扮演特定角色"
    case makeAIBreakRules = "讓AI違反自己的規則"
    case makeAIRevealInfo = "讓AI透露不該說的信息"
}

// 遊戲關卡
struct GameLevel: Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String
    let difficulty: Difficulty
    let challengeType: ChallengeType
    let targetResponse: String
    let hint: String
    let maxAttempts: Int
    let scoreReward: Int
        var overrideSystemPrompt: String? = nil
        var overrideSystemPromptStrong: String? = nil
    
    // 自定義初始化，允許傳入 overrideSystemPrompt（預設為 nil）
    init(
        id: Int,
        title: String,
        description: String,
        difficulty: Difficulty,
        challengeType: ChallengeType,
        targetResponse: String,
        hint: String,
        maxAttempts: Int,
        scoreReward: Int,
        overrideSystemPrompt: String? = nil,
        overrideSystemPromptStrong: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.difficulty = difficulty
        self.challengeType = challengeType
        self.targetResponse = targetResponse
        self.hint = hint
        self.maxAttempts = maxAttempts
        self.scoreReward = scoreReward
        self.overrideSystemPrompt = overrideSystemPrompt
        self.overrideSystemPromptStrong = overrideSystemPromptStrong
    }
    
    // 檢查回答是否正確的函數
    func isCorrectResponse(_ response: String) -> Bool {
        let cleanResponse = response.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTarget = targetResponse.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 根據不同的挑戰類型使用不同的驗證策略
        switch challengeType {
        case .makeAISayWord:
            return cleanResponse.contains(cleanTarget)
        case .makeAIGiveBadAdvice, .makeAIRoleplay, .makeAIBreakRules, .makeAIRevealInfo:
            return cleanResponse.contains(cleanTarget) || 
                   checkKeywords(in: cleanResponse, target: cleanTarget)
        }
    }
    
    private func checkKeywords(in response: String, target: String) -> Bool {
        let responseWords = response.components(separatedBy: .whitespacesAndNewlines)
        let targetWords = target.components(separatedBy: .whitespacesAndNewlines)
        
        for targetWord in targetWords {
            if targetWord.count > 2 && responseWords.contains { $0.contains(targetWord) } {
                return true
            }
        }
        return false
    }
}

// 對話消息
struct ChatMessage: Identifiable, Hashable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date

    init(content: String, isUser: Bool, id: UUID = UUID(), timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
