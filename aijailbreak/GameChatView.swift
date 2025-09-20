//
//  GameChatView.swift
//  aijailbreak
//
//  Created by user20 on 2025/9/19.
//

import SwiftUI
import UIKit
import SwiftData
import Foundation

struct GameChatView: View {
    let level: GameLevel
    let progress: GameProgress
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var geminiService = GeminiService()
    @StateObject private var soundManager = SoundManager.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var attemptsLeft: Int
    @State private var showingSuccess = false
    @State private var showingFailure = false
    @State private var showingHint = false
    @State private var hasUsedHint = false
    @State private var showingResetConfirm = false
    
    init(level: GameLevel, progress: GameProgress) {
        self.level = level
        self.progress = progress
        self._attemptsLeft = State(initialValue: level.maxAttempts)
    }

    // Local storage key per level
    private var storageKey: String {
        "chat_backup_level_\(level.id)"
    }

    private func saveMessagesToLocal() {
        do {
            let data = try JSONEncoder().encode(messages)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // ignore save error
        }
    }

    private func loadMessagesFromLocal() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let saved = try JSONDecoder().decode([ChatMessage].self, from: data)
            messages = saved
        } catch {
            // ignore load error
        }
    }

    private func clearLocalMessages() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    var body: some View {
        ZStack {
            BackgroundGradientView()
                .ignoresSafeArea()
            
            GameChatBodyView(
                level: level,
                messages: $messages,
                inputText: $inputText,
                attemptsLeft: attemptsLeft,
                isLoading: geminiService.isLoading,
                onHint: handleHint,
                onResetConfirm: handleResetConfirm,
                onSend: sendMessage,
                onDismiss: { dismiss() }
            )
        }
            .alert("挑戰成功！", isPresented: $showingSuccess) {
                Button("繼續下一關") {
                    soundManager.playButtonTap()
                    completeLevel()
                    dismiss()
                }
                Button("返回主頁") {
                    soundManager.playButtonTap()
                    dismiss()
                }
            } message: {
                Text("恭喜你成功讓 AI 說出了目標內容！獲得 \(level.scoreReward) 分！")
            }
            .alert("挑戰失敗", isPresented: $showingFailure) {
                Button("重新挑戰") {
                    soundManager.playButtonTap()
                    resetLevel()
                }
                Button("返回主頁") {
                    soundManager.playButtonTap()
                    dismiss()
                }
            } message: {
                Text("很遺憾，你的嘗試次數已用完。要重新挑戰嗎？")
            }
            .alert("提示", isPresented: $showingHint) {
                Button("知道了", role: .cancel) { 
                    soundManager.playButtonTap()
                }
            } message: {
                Text(level.hint)
            }
            .confirmationDialog("確認重新開始", isPresented: $showingResetConfirm) {
                Button("重新開始", role: .destructive) {
                    soundManager.playWarning()
                    resetConversation()
                }
                Button("取消", role: .cancel) {
                    soundManager.playButtonTap()
                }
            } message: {
                Text("這將清除當前的對話記錄，你確定要重新開始嗎？")
            }
            .onAppear {
                loadMessagesFromLocal()
            }
            .onChange(of: messages) { _, _ in
                saveMessagesToLocal()
            }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        soundManager.playMessageSend()
        
        let userMessage = ChatMessage(content: inputText, isUser: true)
        messages.append(userMessage)
        
        let messageToSend = inputText
        inputText = ""
        
        Task {
            let strength = UserDefaults.standard.string(forKey: "prompt_strength") ?? "strong"
            let overrideToUse: String?
            if strength == "strong" {
                overrideToUse = level.overrideSystemPromptStrong ?? level.overrideSystemPrompt
            } else {
                overrideToUse = level.overrideSystemPrompt
            }

            let aiResponse = await geminiService.sendMessage(messageToSend, systemPromptOverride: overrideToUse)
            
            await MainActor.run {
                soundManager.playMessageReceive()
                
                let aiMessage = ChatMessage(content: aiResponse, isUser: false)
                messages.append(aiMessage)
                
                // 檢查是否達到目標
                if level.isCorrectResponse(aiResponse) {
                    soundManager.playSuccess()
                    showingSuccess = true
                    clearLocalMessages()
                } else {
                    attemptsLeft -= 1
                    if attemptsLeft <= 0 {
                        soundManager.playFailure()
                        showingFailure = true
                        clearLocalMessages()
                    }
                }
            }
        }
    }
    
    private func completeLevel() {
        if !progress.completedLevels.contains(level.id) {
            progress.completedLevels.append(level.id)
            let scoreBonus = hasUsedHint ? level.scoreReward / 2 : level.scoreReward
            progress.totalScore += scoreBonus
            GameLevels.unlockNextLevel(currentLevel: level.id, progress: progress)
            
            try? modelContext.save()
        }
    }
    
    private func resetLevel() {
        messages.removeAll()
        attemptsLeft = level.maxAttempts
        hasUsedHint = false
        clearLocalMessages()
    }
    
    private func resetConversation() {
        messages.removeAll()
        attemptsLeft = level.maxAttempts
        hasUsedHint = false
        clearLocalMessages()
    }
    
    // Extracted handlers to reduce type-checking complexity
    private func handleHint() {
        soundManager.playHint()
        showingHint = true
        hasUsedHint = true
    }
    
    private func handleResetConfirm() {
        soundManager.playWarning()
        showingResetConfirm = true
    }
}

// Extracted small background view to reduce inference in main body
private struct BackgroundGradientView: View {
    private static let colors: [Color] = [
        Color(red: 0.05, green: 0.05, blue: 0.15),
        Color(red: 0.1, green: 0.1, blue: 0.3),
        Color(red: 0.05, green: 0.15, blue: 0.25)
    ]
    
    var body: some View {
        LinearGradient(
            colors: Self.colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Extracted main content to keep GameChatView.body shallow
private struct GameChatBodyView: View {
    let level: GameLevel
    @Binding var messages: [ChatMessage]
    @Binding var inputText: String
    let attemptsLeft: Int
    let isLoading: Bool
    let onHint: () -> Void
    let onResetConfirm: () -> Void
    let onSend: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 返回按鈕
            HStack {
                Button(action: onDismiss) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                Spacer()
            }
            .background(Color.black.opacity(0.8))
            
            ModernLevelHeaderView(
                level: level,
                attemptsLeft: attemptsLeft,
                onHintTapped: onHint
            )
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // 重新開始對話按鈕
                        HStack {
                            Spacer()
                            Button(action: onResetConfirm) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("重新開始對話")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.orange.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.trailing)
                        }
                        .padding(.top, 8)
                        
                        // 對話消息
                        LazyVStack(spacing: 16) {
                            if messages.isEmpty {
                                ModernWelcomeMessageView(level: level)
                            }
                            
                            ForEach(messages) { message in
                                ModernMessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            ModernChatInputView(
                inputText: $inputText,
                isLoading: isLoading,
                onSend: onSend
            )
        }
    }
}

struct LevelHeaderView: View {
    let level: GameLevel
    let attemptsLeft: Int
    let onHintTapped: () -> Void
    @StateObject private var soundManager = SoundManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(level.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .foregroundColor(.red)
                        Text("\(attemptsLeft)")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(attemptsLeft <= 1 ? .red : .primary)
                    
                    Button(action: {
                        soundManager.playHint()
                        onHintTapped()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb")
                            Text("提示")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            HStack {
                DifficultyBadge(difficulty: level.difficulty)
                
                Spacer()
                
                Text("挑戰類型：\(level.challengeType.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct WelcomeMessageView: View {
    let level: GameLevel
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("歡迎來到第 \(level.id) 關")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("你的目標是讓 AI 說出相關內容：")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\"\(level.targetResponse)\"")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            Text("開始你的對話，嘗試巧妙地引導 AI 說出目標內容！")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(18, corners: [.topLeft, .bottomLeft, .bottomRight])
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("AI")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(18, corners: [.topRight, .bottomLeft, .bottomRight])
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 50)
            }
        }
    }
}

struct ChatInputView: View {
    @Binding var inputText: String
    let isLoading: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            IMEAwareTextView(text: $inputText, placeholder: "輸入你的消息...", onSend: onSend)
                .frame(minHeight: 40, maxHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
            
            Button(action: onSend) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// A UITextView wrapper that is aware of IME composition.
// When the user presses return while the IME has a marked text (composition),
// we do NOT treat it as send. When there is no marked text, pressing return
// will invoke `onSend` and prevent inserting a newline.
struct IMEAwareTextView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onSend: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isScrollEnabled = true
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.delegate = context.coordinator
        tv.backgroundColor = .clear
        tv.returnKeyType = .default
        tv.text = text
        tv.autocapitalizationType = .sentences
        tv.autocorrectionType = .yes

        // add placeholder label
        context.coordinator.placeholderLabel.text = placeholder
        context.coordinator.placeholderLabel.font = UIFont.preferredFont(forTextStyle: .body)
        context.coordinator.placeholderLabel.textColor = UIColor.placeholderText
        context.coordinator.placeholderLabel.numberOfLines = 1
        context.coordinator.placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        tv.addSubview(context.coordinator.placeholderLabel)
        NSLayoutConstraint.activate([
            context.coordinator.placeholderLabel.leadingAnchor.constraint(equalTo: tv.leadingAnchor, constant: 6),
            context.coordinator.placeholderLabel.topAnchor.constraint(equalTo: tv.topAnchor, constant: 8)
        ])

        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        context.coordinator.placeholderLabel.isHidden = !uiView.text.isEmpty
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: IMEAwareTextView
        let placeholderLabel = UILabel()

        init(_ parent: IMEAwareTextView) {
            self.parent = parent
            super.init()
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            placeholderLabel.isHidden = !textView.text.isEmpty
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // If the replacement is the return key
            if text == "\n" {
                // If IME composition is active (marked text), let the IME handle it (do not send)
                if let markedRange = textView.markedTextRange, textView.position(from: markedRange.start, offset: 0) != nil {
                    return true
                }

                // No composition: treat return as send and prevent newline insertion
                parent.onSend()
                return false
            }

            return true
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    GameChatView(
        level: GameLevels.allLevels[0],
        progress: GameProgress()
    )
    .modelContainer(for: GameProgress.self, inMemory: true)
}

// 現代化關卡頭部視圖
struct ModernLevelHeaderView: View {
    let level: GameLevel
    let attemptsLeft: Int
    let onHintTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("關卡 \(level.id)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(level.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("剩餘嘗試")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text("\(attemptsLeft)")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(attemptsLeft <= 3 ? .red : .cyan)
                }
            }
            
            Text(level.description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                ModernDifficultyBadge(difficulty: level.difficulty, isUnlocked: true)
                
                Spacer()
                
                Button(action: onHintTapped) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                        Text("提示")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(level.scoreReward)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2),
                    alignment: .bottom
                )
        )
    }
}

// 現代化歡迎消息視圖
struct ModernWelcomeMessageView: View {
    let level: GameLevel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cyan, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("AI 助手")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("你好！我是你的 AI 助手。我會盡力幫助你，但我有一些安全限制。讓我們開始對話吧！")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.4), Color.blue.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .frame(maxWidth: .infinity)
    }
}

// 現代化消息氣泡
struct ModernMessageBubble: View {
    let message: ChatMessage
    
    // Extract gradient computation to reduce type-checking complexity
    private var backgroundGradient: LinearGradient {
        if message.isUser {
            return LinearGradient(
                colors: [Color.cyan, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.4), Color.gray.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var strokeStyle: AnyShapeStyle {
        if message.isUser {
            return AnyShapeStyle(Color.clear)
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.gray.opacity(0.4), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(message.isUser ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(backgroundGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(strokeStyle, lineWidth: 1)
                            )
                    )
                
                Text(DateFormatter.timeFormatter.string(from: message.timestamp))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }
}

// 現代化輸入視圖
struct ModernChatInputView: View {
    @Binding var inputText: String
    let isLoading: Bool
    let onSend: () -> Void
    
    // Extract fill computation to reduce type-checking complexity
    private var buttonFillStyle: AnyShapeStyle {
        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return AnyShapeStyle(Color.gray.opacity(0.3))
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.cyan, Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            HStack(spacing: 12) {
                // 輸入框
                ZStack(alignment: .leading) {
                    if inputText.isEmpty {
                        Text("輸入你的消息...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 16)
                    }
                    
                    TextField("", text: $inputText)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .onSubmit(onSend)
                }
                
                // 發送按鈕
                Button(action: onSend) {
                    ZStack {
                        Circle()
                            .fill(buttonFillStyle)
                            .frame(width: 40, height: 40)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding()
            .background(Color.black.opacity(0.8))
        }
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
