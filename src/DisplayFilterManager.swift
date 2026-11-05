import Foundation
import AppKit
import CoreGraphics
import SwiftUI

// MARK: - 基于硬件色调映射表 (Gamma LUT) 的无蒙层原画级滤镜管理器
@MainActor
class DisplayFilterManager {
    static let shared = DisplayFilterManager()
    
    private var restWindow: NSWindow?
    private var keepAliveTimer: Timer?
    
    private init() {
        // 监听屏幕插拔与分辨率变动
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChanges),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        // 监听系统休眠唤醒
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenChanges),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        // 开启轻量级防重置心跳定时器（每 2.5 秒触发一次，仅更新一次显卡 LUT 缓存）
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncHardwareLUT()
            }
        }
    }
    
    @objc private func handleScreenChanges() {
        updateFilter()
    }
    
    func updateFilter() {
        let appState = AppState.shared
        if appState.isEnabled {
            syncHardwareLUT()
        } else {
            restore()
        }
    }
    
    // 核心：直接向显示芯片写入颜色查找表 (Look-Up Table)
    // 根本消除任何透明全屏窗口！文字黑色纯度 100% 保持，彻底杜绝发白发雾
    private func syncHardwareLUT() {
        let appState = AppState.shared
        guard appState.isEnabled else { return }
        
        let scales = appState.selectedPreset.colorScales(strength: Float(appState.filterStrength))
        let dimFactor = Float(1.0 - appState.dimStrength * 0.70)
        
        let sampleCount: UInt32 = 256
        var rTable = [CGGammaValue](repeating: 0, count: Int(sampleCount))
        var gTable = [CGGammaValue](repeating: 0, count: Int(sampleCount))
        var bTable = [CGGammaValue](repeating: 0, count: Int(sampleCount))
        
        for i in 0..<Int(sampleCount) {
            let t = Float(i) / Float(sampleCount - 1)
            // 关键：t = 0（黑色）时，映射结果必定为 0，黑色永远纯黑！
            // t = 1（白色高光）时，压低蓝绿通道，白色自然呈现暖黄温润感
            rTable[i] = min(1.0, max(0.0, t * scales.r * dimFactor))
            gTable[i] = min(1.0, max(0.0, t * scales.g * dimFactor))
            bTable[i] = min(1.0, max(0.0, t * scales.b * dimFactor))
        }
        
        // 获取所有活跃显示器
        var displayCount: UInt32 = 0
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        CGGetOnlineDisplayList(16, &displays, &displayCount)
        
        var appliedDisplays = Set<CGDirectDisplayID>()
        for i in 0..<Int(displayCount) {
            let dID = displays[i]
            CGSetDisplayTransferByTable(dID, sampleCount, &rTable, &gTable, &bTable)
            appliedDisplays.insert(dID)
        }
        
        // 确保主屏幕始终被设置
        let mainID = CGMainDisplayID()
        if !appliedDisplays.contains(mainID) {
            CGSetDisplayTransferByTable(mainID, sampleCount, &rTable, &gTable, &bTable)
        }
    }
    
    // 恢复系统默认色彩校准
    func restore() {
        CGDisplayRestoreColorSyncSettings()
    }
    
    // MARK: - 20-20-20 远眺全屏舒缓提醒
    func showRestOverlay(duration: Int = 20) {
        guard restWindow == nil else { return }
        
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let win = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = NSColor.black.withAlphaComponent(0.85)
        win.level = NSWindow.Level(Int(CGWindowLevelForKey(.screenSaverWindow)))
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.hasShadow = false
        
        let restView = RestReminderView(durationSeconds: duration) { [weak self] in
            self?.dismissRestOverlay()
        }
        win.contentView = NSHostingView(rootView: restView)
        win.makeKeyAndOrderFront(nil)
        
        self.restWindow = win
    }
    
    func dismissRestOverlay() {
        restWindow?.orderOut(nil)
        restWindow = nil
    }
}

