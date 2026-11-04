import Foundation
import SwiftUI
import AppKit

// MARK: - 预设护眼模式
enum PresetMode: String, CaseIterable, Identifiable {
    case warm = "日常防蓝光"
    case deep = "深度护眼"
    case candle = "暗室烛光"
    case paper = "舒缓豆沙绿"
    case custom = "自定义"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .warm: return "sun.max.fill"
        case .deep: return "moon.stars.fill"
        case .candle: return "flame.fill"
        case .paper: return "leaf.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    var subtitle: String {
        switch self {
        case .warm: return "约 3400K 柔和暖光，文档与编程"
        case .deep: return "约 2700K 琥珀金，强效抗眼干涩"
        case .candle: return "约 1900K 烛光，深夜暗光防刺眼"
        case .paper: return "经典淡雅青绿，纸质般舒缓神经"
        case .custom: return "手动自由调整色彩与浓度"
        }
    }
    
    // 基础滤镜颜色（RGB）
    var baseColorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat) {
        switch self {
        case .warm:
            return (1.0, 0.78, 0.28)
        case .deep:
            return (1.0, 0.62, 0.12)
        case .candle:
            return (1.0, 0.44, 0.08)
        case .paper:
            return (0.76, 0.90, 0.72)
        case .custom:
            return (1.0, 0.75, 0.25)
        }
    }
    
    // 默认推荐浓度
    var defaultStrength: Double {
        switch self {
        case .warm: return 0.20
        case .deep: return 0.30
        case .candle: return 0.38
        case .paper: return 0.22
        case .custom: return 0.25
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
            OverlayManager.shared.updateOverlays()
        }
    }
    
    // 当前选中预设
    @Published var selectedPreset: PresetMode {
        didSet {
            UserDefaults.standard.set(selectedPreset.rawValue, forKey: "selectedPreset")
            if selectedPreset != .custom {
                filterStrength = selectedPreset.defaultStrength
            }
            OverlayManager.shared.updateOverlays()
        }
    }
    
    // 蓝光过滤强度 (0.05 ~ 0.65)
    @Published var filterStrength: Double {
        didSet {
            UserDefaults.standard.set(filterStrength, forKey: "filterStrength")
            OverlayManager.shared.updateOverlays()
        }
    }
    
    // 屏幕深度压暗（0.0 ~ 0.50）
    @Published var dimStrength: Double {
        didSet {
            UserDefaults.standard.set(dimStrength, forKey: "dimStrength")
            OverlayManager.shared.updateOverlays()
        }
    }
    
    // 自定义颜色 RGB (0~1)
    @Published var customRed: Double {
        didSet {
            UserDefaults.standard.set(customRed, forKey: "customRed")
            if selectedPreset == .custom { OverlayManager.shared.updateOverlays() }
        }
    }
    @Published var customGreen: Double {
        didSet {
            UserDefaults.standard.set(customGreen, forKey: "customGreen")
            if selectedPreset == .custom { OverlayManager.shared.updateOverlays() }
        }
    }
    @Published var customBlue: Double {
        didSet {
            UserDefaults.standard.set(customBlue, forKey: "customBlue")
            if selectedPreset == .custom { OverlayManager.shared.updateOverlays() }
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
            "filterStrength": 0.22,
            "dimStrength": 0.0,
            "customRed": 1.0,
            "customGreen": 0.78,
            "customBlue": 0.28,
            "isTimerEnabled": true,
            "timerIntervalMinutes": 20,
            "launchAtLogin": true
        ])
        
        self.isEnabled = defaults.bool(forKey: "isEnabled")
        let savedPresetStr = defaults.string(forKey: "selectedPreset") ?? PresetMode.warm.rawValue
        self.selectedPreset = PresetMode(rawValue: savedPresetStr) ?? .warm
        self.filterStrength = defaults.double(forKey: "filterStrength")
        self.dimStrength = defaults.double(forKey: "dimStrength")
        self.customRed = defaults.double(forKey: "customRed")
        self.customGreen = defaults.double(forKey: "customGreen")
        self.customBlue = defaults.double(forKey: "customBlue")
        self.isTimerEnabled = defaults.bool(forKey: "isTimerEnabled")
        self.timerIntervalMinutes = defaults.integer(forKey: "timerIntervalMinutes")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.secondsUntilNextRest = self.timerIntervalMinutes * 60
    }
    
    // 计算当前滤镜生效的 NSColor
    var currentColor: NSColor {
        guard isEnabled else { return .clear }
        let (r, g, b): (CGFloat, CGFloat, CGFloat)
        if selectedPreset == .custom {
            r = CGFloat(customRed)
            g = CGFloat(customGreen)
            b = CGFloat(customBlue)
        } else {
            (r, g, b) = selectedPreset.baseColorComponents
        }
        return NSColor(srgbRed: r, green: g, blue: b, alpha: CGFloat(filterStrength))
    }
    
    var currentDimAlpha: CGFloat {
        guard isEnabled else { return 0.0 }
        return CGFloat(dimStrength)
    }
}

