import SwiftUI

struct RestReminderView: View {
    let durationSeconds: Int
    let onDismiss: () -> Void
    
    @State private var remainingSeconds: Int
    @State private var pulseScale: CGFloat = 1.0
    
    init(durationSeconds: Int = 20, onDismiss: @escaping () -> Void) {
        self.durationSeconds = durationSeconds
        self.onDismiss = onDismiss
        self._remainingSeconds = State(initialValue: durationSeconds)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 32) {
                // 顶部舒缓呼吸动画光环
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.green.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(pulseScale)
                        .animation(
                            Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                    
                    Circle()
                        .stroke(Color.green.opacity(0.6), lineWidth: 4)
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 4) {
                        Text("\(remainingSeconds)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("秒")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                VStack(spacing: 12) {
                    Text("🌿 20-20-20 护眼远眺时刻")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("向 6 米（20 英尺）以外的远处远眺 20 秒，连续眨眼几次，让眼部睫状肌彻底放松。")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: 420)
                }
                
                // 底部跳过按钮
                Button(action: onDismiss) {
                    HStack(spacing: 6) {
                        Text("跳过休息 (按 Esc 键)")
                        Image(systemName: "xmark.circle.fill")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            pulseScale = 1.25
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if remainingSeconds > 1 {
                    remainingSeconds -= 1
                } else {
                    timer.invalidate()
                    onDismiss()
                }
            }
            
            // 监听 Esc 按键事件退出
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // 53 is Esc key
                    onDismiss()
                    return nil
                }
                return event
            }
        }
    }
}

