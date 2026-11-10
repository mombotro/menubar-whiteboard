import Cocoa
import WebKit
import ServiceManagement

final class Panel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class App: NSObject, NSApplicationDelegate, WKScriptMessageHandler, NSWindowDelegate {
    var item: NSStatusItem!
    var panel: Panel!
    var web: WKWebView!
    var monitor: Any?
    var moved = false

    func applicationDidFinishLaunching(_ n: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let b = item.button {
            b.image = NSImage(systemSymbolName: "pencil.and.scribble", accessibilityDescription: "Whiteboard")
            b.target = self; b.action = #selector(clicked)
            b.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let cfg = WKWebViewConfiguration()
        for n in ["save", "close", "resize", "move"] { cfg.userContentController.add(self, name: n) }
        web = WKWebView(frame: .zero, configuration: cfg)
        if let url = Bundle.main.url(forResource: "whiteboard", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        panel = Panel(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                      styleMask: [.borderless, .nonactivatingPanel],
                      backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.isMovable = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        web.setValue(false, forKey: "drawsBackground")
        web.wantsLayer = true
        web.layer?.cornerRadius = 12
        web.layer?.masksToBounds = true
        panel.contentView = web
        panel.delegate = self
        if let sz = UserDefaults.standard.array(forKey: "size") as? [Double], sz.count == 2 {
            panel.setContentSize(NSSize(width: sz[0], height: sz[1]))
        }
    }

    @objc func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp { showMenu(); return }
        toggle()
    }

    func showMenu() {
        let menu = NSMenu()
        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Whiteboard", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            let a = NSAlert(); a.messageText = "Login item failed"; a.informativeText = error.localizedDescription; a.runModal()
        }
    }

    @objc func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        guard let b = item.button, let bw = b.window else { return }
        let r = bw.frame
        var f = panel.frame
        f.origin.x = min(max(r.midX - f.width / 2, (bw.screen?.frame.minX ?? 0) + 8),
                         (bw.screen?.frame.maxX ?? 1e5) - f.width - 8)
        f.origin.y = r.minY - f.height - 2
        if !moved { panel.setFrame(f, display: true) }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
    }

    func hide() {
        panel.orderOut(nil)
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        if m.name == "close" { hide(); return }
        if m.name == "move", let d = m.body as? [Double], d.count == 2 {
            var o = panel.frame.origin
            o.x += d[0]; o.y -= d[1]
            panel.setFrameOrigin(o)
            moved = true
            return
        }
        if m.name == "resize", let d = m.body as? [Double], d.count == 2 {
            var f = panel.frame
            let w = max(480, f.width + d[0]), h = max(360, f.height + d[1])
            f.origin.y += f.height - h; f.size = NSSize(width: w, height: h)
            panel.setFrame(f, display: true)
            UserDefaults.standard.set([w, h], forKey: "size")
            return
        }
        guard let s = m.body as? String, let comma = s.firstIndex(of: ","),
              let data = Data(base64Encoded: String(s[s.index(after: comma)...])),
              let img = NSImage(data: data) else { return }
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Pictures/Whiteboard")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let file = dir.appendingPathComponent("whiteboard_\(fmt.string(from: Date())).png")
        try? data.write(to: file)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([img])
        NSSound(named: "Tink")?.play()
        web.evaluateJavaScript("typeof toast==='function'&&toast('Saved to Pictures/Whiteboard + copied')")
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = App()
app.delegate = delegate
app.run()
