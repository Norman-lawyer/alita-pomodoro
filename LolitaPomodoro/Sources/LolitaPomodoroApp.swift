import SwiftUI
import Combine

@main
struct LolitaPomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var timer: PomodoroTimer!
    var statusItemTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        timer = PomodoroTimer()
        
        setupStatusItem()
        setupWindow()
        setupAppEvents()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            updateStatusItemTitle()
            button.action = #selector(toggleWindow)
            button.target = self
        }
    }
    
    private func setupWindow() {
        let contentView = ContentView(timer: timer)
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame.size = NSSize(width: 340, height: 520)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 520),
            styleMask: [.closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.contentView = hostingController.view
        window.isMovableByWindowBackground = true
        window.center()
        window.level = .floating
        window.hasShadow = true
        window.backgroundColor = .clear
        window.isOpaque = false
        
        // 圆角
        window.contentView?.layer?.cornerRadius = 20
        window.contentView?.layer?.masksToBounds = true
        
        // 启动时显示窗口
        window.makeKeyAndOrderFront(nil)
    }
    
    private func setupAppEvents() {
        NSApp.windows.forEach { window in
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowWillClose),
                name: NSWindow.willCloseNotification,
                object: window
            )
        }
    }
    
    @objc private func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == window {
            timer.stop()
        }
    }
    
    @objc func toggleWindow() {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            window.center()
        }
    }
    
    func updateStatusItemTitle() {
        // 直接设置按钮的图标和标题
        let symbolName: String
        switch timer.currentMode {
        case .work: symbolName = "brain"
        case .shortBreak: symbolName = "leaf"
        case .longBreak: symbolName = "moon"
        }
        
        // 设置图标
        let iconImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        iconImage?.size = NSSize(width: 14, height: 14)
        statusItem.button?.image = iconImage
        statusItem.button?.imagePosition = .imageLeft
        
        // 设置标题（时间）
        statusItem.button?.title = timer.formattedTime
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        timer.stop()
        statusItemTimer?.invalidate()
    }
}
