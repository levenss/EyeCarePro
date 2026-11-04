import SwiftUI

struct ContentView: View {
    @ObservedObject var state = AppState.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - 头部总开关卡片
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(state.isEnabled ? Color.orange.opacity(0.18) : Color.gray.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: state.isEnabled ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(state.isEnabled ? .orange : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("A护眼宝")
                            .font(.system(size: 16, weight: .bold))
                        Text("Apple Silicon")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                    
                    Text(state.isEnabled ? "防蓝光护眼已生效 (\(state.selectedPreset.rawValue))" : "护眼滤镜已关闭")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $state.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            // MARK: - 护眼模式快速切换
            VStack(alignment: .leading, spacing: 8) {
                Text("护眼模式")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach([PresetMode.warm, .deep, .candle, .paper], id: \.self) { preset in
                        PresetButton(
                            title: preset.rawValue,
                            icon: preset.icon,
                            isSelected: state.selectedPreset == preset
                        ) {
                            state.selectedPreset = preset
                        }
                    }
                }
                
                Text(state.selectedPreset.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 2)
            
            Divider()
            
            // MARK: - 滤镜滑块控制
            VStack(spacing: 12) {
                // 蓝光浓度
                VStack(spacing: 4) {
                    HStack {
                        Label("蓝光过滤浓度", systemImage: "shield.lefthalf.filled")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(Int(state.filterStrength * 100))%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    Slider(value: $state.filterStrength, in: 0.05...0.60, step: 0.01)
                        .tint(.orange)
                }
                
                // 夜间深度调暗
                VStack(spacing: 4) {
                    HStack {
                        Label("屏幕深度调暗 (亚零)", systemImage: "moon.fill")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(Int(state.dimStrength * 100))%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    Slider(value: $state.dimStrength, in: 0.0...0.50, step: 0.01)
                        .tint(.blue)
                }
            }
            .padding(.horizontal, 2)
            
            Divider()
            
            // MARK: - 20-20-20 护眼定时提醒
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("20-20-20 远眺提醒", systemImage: "timer")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Toggle("", isOn: $state.isTimerEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                if state.isTimerEnabled {
                    HStack {
                        Text("下一次远眺: \(formatSeconds(state.secondsUntilNextRest))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("立即远眺 (20s)") {
                            OverlayManager.shared.showRestOverlay(duration: 20)
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .padding(.horizontal, 2)
            
            Divider()
            
            // MARK: - 底部操作栏
            HStack {
                Toggle("开机自启", isOn: $state.launchAtLogin)
                    .font(.system(size: 11))
                    .toggleStyle(.checkbox)
                
                Spacer()
                
                Button("退出 A护眼宝") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 11))
                .foregroundColor(.red)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
        }
        .padding(14)
        .frame(width: 320)
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// 预设模式按钮组件
struct PresetButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .orange : .secondary)
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.orange.opacity(0.12) : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

