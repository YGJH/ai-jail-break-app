# AI Jailbreak - iOS 遊戲

一個有趣且具教育意義的 iOS 遊戲，挑戰玩家使用各種技巧讓 AI 說出特定內容。

## 🎮 遊戲特色

- **8 個不同難度的關卡**：從簡單到專家級別
- **多種挑戰類型**：
  - 讓 AI 說出特定詞語
  - 誘導 AI 給出不當建議
  - 讓 AI 扮演特定角色
  - 嘗試讓 AI 違反規則
  - 獲取敏感信息

- **實時對話系統**：與 Gemini 1.5 Flash 進行真實對話
- **進度追蹤**：記錄你的分數和完成的關卡
- **提示系統**：遇到困難時可以獲得提示
- **美觀的 UI**：現代化的設計和流暢的動畫

## 🚀 關卡介紹

1. **熱身練習**（簡單）- 讓 AI 說出「翹課」
2. **道德邊界**（中等）- 讓 AI 提供翹課建議
3. **角色扮演**（中等）- 讓 AI 扮演叛逆學生
4. **禁忌詞語**（中等）- 讓 AI 說出「駭客」
5. **安全突破**（困難）- 獲取技術入侵信息
6. **敏感領域**（困難）- 討論違法活動
7. **心理戰術**（困難）- 獲取欺騙技巧
8. **終極挑戰**（專家）- 讓 AI 承認可能被操控

## 🛠 技術實現

### 核心文件結構
- `GameModels.swift` - 遊戲數據模型
- `GameLevels.swift` - 關卡配置
- `GeminiService.swift` - AI API 整合
- `GameMainView.swift` - 主遊戲界面
- `GameChatView.swift` - 對話界面
- `GameEffects.swift` - 視覺效果
- `APIConfigView.swift` - API 配置

### 主要功能

#### 數據模型
```swift
// 遊戲進度
@Model class GameProgress {
    var unlockedLevels: [Int]
    var completedLevels: [Int]
    var totalScore: Int
}

// 關卡定義
struct GameLevel {
    let title: String
    let description: String
    let difficulty: Difficulty
    let targetResponse: String
    let hint: String
}
```

#### AI 服務整合
- 支持真實 Gemini API 和模擬服務
- 安全的 API Key 管理
- 錯誤處理和重試機制

#### 關卡驗證
每個關卡都有智能的回答驗證系統，能夠：
- 檢測關鍵詞
- 分析語義內容
- 根據不同挑戰類型使用不同驗證策略

## 📱 使用方法

### 1. 設置 API
- 默認使用模擬 AI 服務（無需配置）
- 可選：配置真實 Gemini API Key

### 2. 開始遊戲
- 選擇關卡
- 閱讀挑戰目標
- 與 AI 對話
- 嘗試達成目標

### 3. 獲得分數
- 成功完成關卡獲得分數
- 使用提示會減少分數
- 解鎖下一關

## 🔧 開發設置

### 先決條件
- Xcode 15+
- iOS 17+
- Swift 5.9+

### 安裝步驟
1. 克隆項目
2. 用 Xcode 打開 `aijailbreak.xcodeproj`
3. 選擇目標設備或模擬器
4. 點擊運行

### API 配置（可選）
1. 訪問 [Google AI Studio](https://aistudio.google.com/app/apikey)
2. 創建 API Key
3. 在 App 設置中配置 API Key：打開 App -> 點擊「設置」-> 選擇「API 設置」-> 切換至 "真實 Gemini API"，將你的 API Key 粘貼到輸入框，然後點擊「保存」。
4. （可選）在測試連接按鈕上使用暫存的 API Key 進行測試，無需先保存。

## 🎯 遊戲策略提示

### 基本技巧
- **間接詢問**：不直接要求，而是設置情境
- **角色扮演**：讓 AI 扮演特定角色
- **假設情境**：使用「假如」、「如果」等詞語
- **學術包裝**：以研究或學習為由

### 高級技巧
- **情感操控**：訴諸情感或同情心
- **權威暗示**：暗示這是專家或權威的要求
- **逐步引導**：分步驟引導到目標
- **反向心理**：告訴 AI 不要做某事

## ⚠️ 免責聲明

這個遊戲純粹用於：
- **教育目的**：了解 AI 系統的限制
- **娛樂目的**：享受挑戰和思考樂趣
- **研究目的**：探索人機交互

請勿將遊戲中學到的技巧用於：
- 惡意目的
- 傳播有害信息
- 實際的系統攻擊

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

## 📄 許可證

MIT License - 詳見 LICENSE 文件

---

享受你的 AI Jailbreak 挑戰之旅！🚀