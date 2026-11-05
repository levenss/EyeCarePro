import Foundation
import SwiftUI
import AppKit

// MARK: - 预设护眼模式
enum PresetMode: String, CaseIterable, Identifiable {
    case warm = "日常防蓝光"
    case deep = "深度护眼"
    case candle = "暗室烛光"
    case paper = "舒缓豆沙绿"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .warm: return "sun.max.fill"
        case .deep: return "moon.stars.fill"
        case .candle: return "flame.fill"
        case .paper: return "leaf.fill"
        }
    }
    
    var subtitle: String {
        switch self {
        case .warm: return "约 3400K 柔和暖光，文档与编程"
        case .deep: return "约 2700K 琥珀金，强效抗眼干涩"
        case .candle: return "约 1900K 烛光，深夜暗光防刺眼"
        case .paper: return "经典淡雅青绿，纸质般舒缓神经"
        }
    }
    
    // 计算基于硬件 LUT 的 (Red, Green, Blue) 衰减系数
    // 关键：只降低高能蓝绿光，不抬高黑色基底，文字锐度 100% 保持纯黑！
    func colorScales(strength: Float) -> (r: Float, g: Float, b: Float) {
        let s = max(0.05, min(0.95, strength))
        switch self {
        case .warm:
            // 适度压制蓝光，微调绿光，保持极高文字反差
            return (1.0, 1.0 - s * 0.15, 1.0 - s * 0.55)
        case .deep:
            // 强力压制蓝光，琥珀暖色
            return (1.0, 1.0 - s * 0.30, 1.0 - s * 0.85)
        case .candle:
            // 极深烛光模式，完全去除有害高频蓝光
            return (1.0, 1.0 - s * 0.48, 1.0 - s * 0.98)
        case .paper:
            // 豆沙绿纸质模式，红蓝同降，绿光突出
            return (1.0 - s * 0.28, 1.0, 1.0 - s * 0.38)
        }
    }
    
    var defaultStrength: Double {
        switch self {
        case .warm: return 0.35
        case .deep: return 0.50
        case .candle: return 0.65
        case .paper: return 0.35
        }
    }
}

// MARK: - 全局状态管理
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    // 核心开关
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "isEnabled")
            DisplayFilterManager.shared.updateFilter()
        }
    }
    
    // 当前选中预设
    @Published var selectedPreset: PresetMode {
        didSet {
            UserDefaults.standard.set(selectedPreset.rawValue, forKey: "selectedPreset")
            filterStrength = selectedPreset.defaultStrength
            DisplayFilterManager.shared.updateFilter()
        }
    }
    
    // 蓝光过滤强度 (0.10 ~ 0.90)
    @Published var filterStrength: Double {
        didSet {
            UserDefaults.standard.set(filterStrength, forKey: "filterStrength")
            DisplayFilterManager.shared.updateFilter()
        }
    }
    
    // 屏幕深度压暗 (0.0 ~ 0.50)
    @Published var dimStrength: Double {
        didSet {
            UserDefaults.standard.set(dimStrength, forKey: "dimStrength")
            DisplayFilterManager.shared.updateFilter()
        }
    }
    
    // 20-20-20 定时护眼提醒
    @Published var isTimerEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isTimerEnabled, forKey: "isTimerEnabled")
            RestTimerManager.shared.syncTimerState()
        }
    }
    
    @Published var timerIntervalMinutes: Int {
        didSet {
            UserDefaults.standard.set(timerIntervalMinutes, forKey: "timerIntervalMinutes")
            RestTimerManager.shared.syncTimerState()
        }
    }
    
    @Published var secondsUntilNextRest: Int = 1200
    
    // 开机自启动
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            AppLaunchManager.setLaunchAtLogin(launchAtLogin)
        }
    }
    
    private init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "isEnabled": true,
            "selectedPreset": PresetMode.warm.rawValue,
            "filterStrength": 0.35,
            "dimStrength": 0.0,
            "isTimerEnabled": true,
            "timerIntervalMinutes": 20,
            "launchAtLogin": true
        ])
        
        self.isEnabled = defaults.bool(forKey: "isEnabled")
        let savedPresetStr = defaults.string(forKey: "selectedPreset") ?? PresetMode.warm.rawValue
        self.selectedPreset = PresetMode(rawValue: savedPresetStr) ?? .warm
        self.filterStrength = defaults.double(forKey: "filterStrength")
        self.dimStrength = defaults.double(forKey: "dimStrength")
        self.isTimerEnabled = defaults.bool(forKey: "isTimerEnabled")
        self.timerIntervalMinutes = defaults.integer(forKey: "timerIntervalMinutes")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.secondsUntilNextRest = self.timerIntervalMinutes * 60
    }
}
