import Foundation
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. 设置菜单栏状态图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "A护眼宝") {
                image.isTemplate = true
                button.image = image
            }
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // 2. 初始化 SwiftUI 弹出面板
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 440)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
        self.popover = popover
        
        // 3. 激活硬件 LUT 调光与定时器
        Task { @MainActor in
            DisplayFilterManager.shared.updateFilter()
            RestTimerManager.shared.syncTimerState()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 退出时确保恢复系统 ColorSync 色彩
        Task { @MainActor in
            DisplayFilterManager.shared.restore()
        }
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
