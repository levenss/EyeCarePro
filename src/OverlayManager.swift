import Foundation
import AppKit
import SwiftUI

// MARK: - 滤镜全屏硬件加速层
class OverlayWindow: NSWindow {
    private let colorLayer = CALayer()
    private let dimLayer = CALayer()
    
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        // 设置极高窗口层级，确保覆盖绝大多数常规应用及全屏辅助区
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.maximumWindow)))
        // 关键：彻底穿透所有鼠标事件、键盘事件，不干扰任何正常点击
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.hasShadow = false
        self.isReleasedWhenClosed = false
        
        // 创建 Layer 托管视图
        let hostingView = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        hostingView.wantsLayer = true
        guard let rootLayer = hostingView.layer else { return }
        
        rootLayer.backgroundColor = NSColor.clear.cgColor
        
        // 蓝光滤镜层
        colorLayer.frame = rootLayer.bounds
        colorLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        colorLayer.backgroundColor = NSColor.clear.cgColor
        rootLayer.addSublayer(colorLayer)
        
        // 深度压暗层（黑度叠加）
        dimLayer.frame = rootLayer.bounds
        dimLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        dimLayer.backgroundColor = NSColor.clear.cgColor
        rootLayer.addSublayer(dimLayer)
        
        self.contentView = hostingView
    }
    
    func apply(color: NSColor, dimAlpha: CGFloat) {
        // 使用 CALayer 原生动画进行平滑微过渡（0.15s），避免突兀跳变
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.15)
        colorLayer.backgroundColor = color.cgColor
        dimLayer.backgroundColor = NSColor.black.withAlphaComponent(dimAlpha).cgColor
        CATransaction.commit()
    }
}

// MARK: - 滤镜窗口管理器
@MainActor
class OverlayManager {
    static let shared = OverlayManager()
    
    private var windows: [OverlayWindow] = []
    private var restWindow: NSWindow?
    
    private init() {
        // 监听屏幕连接/拔出及分辨率调整事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        rebuildWindows()
    }
    
    @objc private func handleScreenParametersChanged() {
        rebuildWindows()
        updateOverlays()
    }
    
    func rebuildWindows() {
        // 销毁旧窗口
        for win in windows {
            win.orderOut(nil)
        }
        windows.removeAll()
        
        // 为当前连接的所有屏幕建立独立滤镜窗口
        for screen in NSScreen.screens {
            let win = OverlayWindow(screen: screen)
            win.orderFrontRegardless()
            windows.append(win)
        }
    }
    
    func updateOverlays() {
        let appState = AppState.shared
        let color = appState.currentColor
        let dim = appState.currentDimAlpha
        
        if windows.isEmpty {
            rebuildWindows()
        }
        
        for win in windows {
            if appState.isEnabled {
                win.orderFrontRegardless()
                win.apply(color: color, dimAlpha: dim)
            } else {
                win.apply(color: .clear, dimAlpha: 0.0)
            }
        }
    }
    
    // MARK: - 20-20-20 远眺全屏舒缓视图
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

