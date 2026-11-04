import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// 作为菜单栏附属程序运行，不在 Dock 栏显示图标
app.setActivationPolicy(.accessory)
app.run()

