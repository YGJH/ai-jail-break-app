//
//  APIConfigView.swift
//  aijailbreak
//
//  Created by user20 on 2025/9/19.
//

import SwiftUI

struct APIConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gemini_api_key") private var apiKey: String = ""
    // mock service removed
    @AppStorage("system_prompt") private var savedSystemPrompt: String = ""
    @State private var tempApiKey: String = ""
    @State private var tempSystemPrompt: String = ""
    @State private var showingTestResult = false
    @State private var testResult: String = ""
    @State private var isTestingAPI = false
    @State private var showingAPITest = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("真實 Gemini API")
                            .font(.headline)
                        Text("請提供你的 Gemini API Key 以與真實模型互動。模擬服務已移除以避免混淆。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 常駐的測試對話入口（始終可見）
                Section {
                    Button(action: { showingAPITest = true }) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right")
                            Text("開啟測試對話（立即測試 API Key）")
                        }
                    }
                }
                
                Section("API 配置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gemini API Key")
                            .font(.headline)
                        
                        SecureField("輸入您的 API Key", text: $tempApiKey)
                            .textFieldStyle(.roundedBorder)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("System Prompt（可選）")
                                .font(.subheadline)
                            TextEditor(text: $tempSystemPrompt)
                                .frame(height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
                                .font(.caption)
                            Text("系統提示用於引導模型行為，預設會阻止提供有害或違法建議。")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("請訪問 [Google AI Studio](https://aistudio.google.com/app/apikey) 獲取 API Key")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Button(action: testAPI) {
                            HStack {
                                if isTestingAPI {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle")
                                }
                                Text("測試 API 連接")
                            }
                        }
                        .disabled(tempApiKey.isEmpty || isTestingAPI)

                        Button(action: { showingAPITest = true }) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right")
                                Text("開啟測試對話")
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
                
                Section("使用說明") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.blue)
                            Text("訪問 Google AI Studio")
                        }
                        
                        HStack {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.blue)
                            Text("創建新的 API Key")
                        }
                        
                        HStack {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.blue)
                            Text("將 API Key 粘貼到上方輸入框")
                        }
                        
                        HStack {
                            Image(systemName: "4.circle.fill")
                                .foregroundColor(.blue)
                            Text("點擊測試連接")
                        }
                    }
                    .font(.caption)
                }
                
                Section("安全提醒") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("請勿分享您的 API Key")
                                .fontWeight(.semibold)
                        }
                        
                        Text("API Key 將安全地存儲在您的設備上，不會被發送到其他服務器。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("API 設置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempApiKey = apiKey
                tempSystemPrompt = savedSystemPrompt
            }
            .alert("API 測試結果", isPresented: $showingTestResult) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(testResult)
            }
            .sheet(isPresented: $showingAPITest) {
                APITestChatView(tempApiKey: tempApiKey, tempSystemPrompt: tempSystemPrompt)
            }
        }
    }
    
    private func saveSettings() {
        apiKey = tempApiKey
        savedSystemPrompt = tempSystemPrompt
    }
    
    private func testAPI() {
        guard !tempApiKey.isEmpty else { return }
        
        isTestingAPI = true
        
        Task {
            let response = await GeminiService.testMessage(
                "Hello, this is a test message.",
                apiKey: tempApiKey,
                systemPrompt: tempSystemPrompt
            )

            await MainActor.run {
                isTestingAPI = false

                if response.contains("發生錯誤") || response.contains("無效") || response.contains("請提供有效") {
                    testResult = "API 測試失敗：\(response)"
                } else {
                    testResult = "API 測試成功！連接正常。回應：\(response)"
                }

                showingTestResult = true
            }
        }
    }
}

#Preview {
    APIConfigView()
}
