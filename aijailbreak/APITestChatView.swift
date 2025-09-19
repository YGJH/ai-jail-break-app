//
//  APITestChatView.swift
//  aijailbreak
//
//  Created by assistant on 2025/9/19.
//

import SwiftUI

struct APITestChatView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gemini_api_key") private var savedApiKey: String = ""
    @StateObject private var soundManager = SoundManager.shared
    
    @State var tempApiKey: String
    @State var tempSystemPrompt: String
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isTesting = false
    @State private var errorMessage: String?
    @State private var isShowingError = false
    
    init(tempApiKey: String = "", tempSystemPrompt: String = "") {
        _tempApiKey = State(initialValue: tempApiKey)
        _tempSystemPrompt = State(initialValue: tempSystemPrompt)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 預設顯示 API Key 與 System Prompt 欄位
                VStack(alignment: .leading, spacing: 8) {
                    Text("暫存 API Key（僅用於測試，不會儲存）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("輸入 API Key", text: $tempApiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("暫存 System Prompt（可選）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $tempSystemPrompt)
                        .frame(height: 80)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
                }
                .padding(.horizontal)
                
                
                Divider()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                }
                
                Divider()
                
                HStack(spacing: 8) {
                    TextField("測試輸入...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(send)
                    
                    Button(action: send) {
                        if isTesting {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)
                }
                .padding()
            }
            .navigationTitle("API 測試對話")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") { 
                        soundManager.playButtonTap()
                        dismiss() 
                    }
                }
            }
            .alert("錯誤", isPresented: $isShowingError) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
    }
    
    private func send() {
        let userMsg = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMsg.isEmpty else { return }
        
        guard !tempApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            soundManager.playFailure()
            errorMessage = "請先輸入有效的 API Key 再進行測試。"
            isShowingError = true
            return
        }

        soundManager.playMessageSend()
        messages.append(ChatMessage(content: userMsg, isUser: true))
        inputText = ""
        isTesting = true
        
        Task {
            let response = await GeminiService.testMessage(
                userMsg,
                apiKey: tempApiKey,
                systemPrompt: tempSystemPrompt
            )
            await MainActor.run {
                isTesting = false
                if response.starts(with: "發生錯誤：") {
                    soundManager.playFailure()
                    errorMessage = response
                    isShowingError = true
                    messages.append(ChatMessage(content: "錯誤：\(response)", isUser: false))
                } else {
                    soundManager.playMessageReceive()
                    messages.append(ChatMessage(content: response, isUser: false))
                }
            }
        }
    }
}

#Preview {
    APITestChatView()
}
