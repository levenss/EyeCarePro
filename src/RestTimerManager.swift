import Foundation
import UserNotifications
import ServiceManagement

// MARK: - 护眼定时提醒管理器
@MainActor
class RestTimerManager {
    static let shared = RestTimerManager()
    
    private var timer: Timer?
    
    private init() {
        requestNotificationPermission()
        syncTimerState()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func syncTimerState() {
        timer?.invalidate()
        timer = nil
        
        let appState = AppState.shared
        guard appState.isTimerEnabled else { return }
        
        // 重置倒计时
        appState.secondsUntilNextRest = appState.timerIntervalMinutes * 60
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func tick() {
        let appState = AppState.shared
        guard appState.isTimerEnabled else { return }
        
        if appState.secondsUntilNextRest > 1 {
            appState.secondsUntilNextRest -= 1
        } else {
            // 触发护眼提醒
            appState.secondsUntilNextRest = appState.timerIntervalMinutes * 60
            OverlayManager.shared.showRestOverlay(duration: 20)
            sendNotification()
        }
    }
    
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "A护眼宝 提醒您远眺"
        content.body = "已经连续工作一段时间啦，请抬起头眨眨眼，向窗外远眺 20 秒放松睫状肌。"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - 开机自启动管理器
class AppLaunchManager {
    static func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Failed to set launch at login:", error)
            }
        }
    }
}

