# EyeCarePro (A护眼宝) - 专为 Apple Silicon 打造的原生 macOS 护眼与防蓝光工具

[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue)](https://apple.com)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(ARM64)-orange)](https://apple.com)
[![Language](https://img.shields.io/badge/Language-Swift%206-green)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-purple)](LICENSE)

一款专为 Apple Silicon (M1/M2/M3/M4/M5 系列芯片) 深度定制的原生 macOS 护眼、防蓝光与屏幕调暗工具。体积仅 **400 KB**，**0.0% CPU 占用**，无任何第三方依赖。

---

## 🌟 核心特性

1. **100% Apple Silicon 原生 (ARM64)**
   * 基于 Swift + AppKit + SwiftUI 原生编译，不依赖任何 Rosetta 2 转译，彻底解决 macOS 28 及后续版本兼容性问题。
2. **多模式防蓝光滤镜**
   * **日常防蓝光 (约 3400K)**：柔和淡暖光，消除刺眼白光，对日常办公与代码色彩几乎无干扰。
   * **深度护眼 (约 2700K)**：琥珀暖金，有效缓解长时间用眼的眼干、眼涩与眼酸。
   * **暗室烛光 (约 1900K)**：关灯或深夜环境下的深暖烛光模式，彻底杜绝强光刺激。
   * **舒缓豆沙绿**：经典纸质豆沙绿模式，温和抚平视疲劳。
3. **亚零级屏幕深度调暗 (Sub-zero Dimming)**
   * 在 Mac 硬件最低亮度之下，可通过软件层继续平滑压暗屏幕（0% ~ 50%），深夜不刺眼。
4. **完全鼠标穿透 (Event Pass-Through)**
   * 采用高层级硬件加速窗口覆盖，所有鼠标点击、滑动、拖拽完全穿透，日常操作零延迟、零阻挡。
   * 全面支持多显示器热插拔与自动跟随。
5. **20-20-20 科学远眺护眼提醒**
   * 内置 20-20-20 护眼法则计时器，定时引导远眺 20 秒，提供呼吸式全屏眼肌放松界面（按 Esc 键随时退出）。
6. **纯净常驻菜单栏**
   * 极简菜单栏常驻（不挤占 Dock 栏），支持开机自启。

---

## 🛠️ 技术栈与编译方式

### 开发工具链
* **编程语言**：Apple Swift 6
* **UI 框架**：SwiftUI + AppKit (Cocoa)
* **图形渲染**：CoreAnimation (CALayer) 硬件加速层
* **服务管理**：ServiceManagement (SMAppService)
* **编译器**：Apple `swiftc` (无需重型 Xcode IDE，只要系统有 Command Line Tools 即可秒级编译)

### 一键编译运行

```bash
# 1. 克隆本仓库
git clone https://github.com/your-username/EyeCarePro.git
cd EyeCarePro

# 2. 赋予脚本执行权限并一键编译
chmod +x build.sh
./build.sh

# 3. 安装到应用程序目录
cp -R "A护眼宝.app" /Applications/
```

---

## 📄 源码架构目录

```text
├── src/
│   ├── main.swift              # 程序入口与生命周期托管
│   ├── AppDelegate.swift       # 菜单栏 StatusItem 与 Popover 控制器
│   ├── Models.swift            # 滤镜预设、配置持久化与 AppState
│   ├── OverlayManager.swift    # 多屏硬件加速全屏穿透滤镜窗口管理
│   ├── RestReminderView.swift  # 20-20-20 远眺全屏放松呼吸视图
│   ├── RestTimerManager.swift  # 护眼定时提醒与开机自启服务
│   └── ContentView.swift       # 现代 SwiftUI 菜单栏控制面板
├── AppIcon.icns                # 1024x1024 独立原创 macOS Squircle 图标
├── Info.plist                  # Bundle 元数据配置
├── build.sh                    # 一键极速构建与打包脚本
├── LICENSE                     # MIT 开源许可证
└── README.md
```

---

## ⚖️ 开源协议与版权声明

本项目基于 **MIT License** 完全开源。
* 本项目所有 Swift 源代码均为**独立全新编写 (Clean-room Implementation)**，未包含任何旧版商业软件的代码或逆向资产。
* 图标资源 `AppIcon.icns` 为独立自主生成的 1024x1024 高清矢量图层，不存在第三方知识产权纠纷。
* 欢迎提交 PR 与 Issue！
