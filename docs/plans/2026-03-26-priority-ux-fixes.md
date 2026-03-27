# Priority UX Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 按用户指定优先级修复 5 个最关键的用户体验问题：保存部署闭环、预览可信度、`app_options` 图形化、首次使用诊断、安全试错。

**Architecture:** 先把可测试的逻辑从 `ConfigManager` 中抽清楚，再补 SwiftUI 界面。读写仍以 `~/Library/Rime` 为中心，但增加部署结果建模、诊断结果建模、按应用覆盖模型，以及脏状态/重置入口。

**Tech Stack:** Swift 5.9, SwiftUI, XCTest, Yams

### Task 1: 建立测试入口

**Files:**
- Modify: `Package.swift`
- Create: `Tests/RimeConfiguratorTests/ConfigManagerTests.swift`

**Steps:**
1. 添加 `testTarget`，让模块可被 XCTest 导入。
2. 为配置保存、`app_options` 序列化、诊断逻辑写失败测试。
3. 运行测试，确认先红。

### Task 2: 保存与部署闭环

**Files:**
- Modify: `Sources/Models/ConfigManager.swift`
- Modify: `Sources/ContentView.swift`
- Modify: `Sources/Views/SavedResultSheet.swift`

**Steps:**
1. 引入明确的部署结果模型，区分已部署、需手动部署、保存失败。
2. 让 UI 根据真实结果渲染反馈，而不是固定显示手动部署提示。
3. 为部署结果驱动的提示补测试或可验证辅助逻辑。

### Task 3: 预览可信度

**Files:**
- Modify: `Sources/Views/CandidatePreview.swift`
- Modify: `Sources/Views/AppearanceView.swift`

**Steps:**
1. 让预览覆盖更多参数：边框、分页、透明背景、文字方向等。
2. 对暂未 1:1 模拟的能力给出明确说明，而不是假装完整预览。
3. 通过代码和手动构建验证预览不会破坏当前界面。

### Task 4: `app_options` 图形化

**Files:**
- Modify: `Sources/Models/ConfigManager.swift`
- Modify: `Sources/Views/BehaviorView.swift`

**Steps:**
1. 增加按应用覆盖的数据模型与读写支持。
2. 在行为页增加可编辑列表，优先支持 `ascii_mode`、`inline`、`no_inline`、`vim_mode`。
3. 为 YAML 解析/保存补测试。

### Task 5: 首次使用诊断与安全试错

**Files:**
- Modify: `Sources/Models/ConfigManager.swift`
- Modify: `Sources/ContentView.swift`
- Modify: `Sources/Views/SchemasView.swift`
- Modify: `Sources/Views/AppearanceView.swift`
- Modify: `Sources/Views/BehaviorView.swift`

**Steps:**
1. 输出安装/路径/配置诊断，修正错误路径提示。
2. 增加脏状态、恢复默认、放弃修改确认等安全试错能力。
3. 为诊断与脏状态逻辑补测试。

### Task 6: 验证

**Files:**
- None

**Steps:**
1. 运行单元测试。
2. 运行 `swift build`。
3. 记录 fresh evidence 后再交付。
