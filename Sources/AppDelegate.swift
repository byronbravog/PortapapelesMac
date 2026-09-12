import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let historyManager = HistoryManager()
    private lazy var clipboardMonitor = ClipboardMonitor { [weak self] item in
        self?.historyManager.addItem(item)
    }
    
    override init() {
        super.init()
        // El monitor se inicializa en lazy
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        _ = clipboardMonitor
        setupStatusItem()
        setupPopover()
        print("✅ Portapapeles iniciado correctamente")
    }
    
    private func setupStatusItem() {
        statusItem.isVisible = true

        if let button = statusItem.button {
            button.image = clipboardIcon()
            button.title = "BB"
            button.imagePosition = .imageLeading
            button.toolTip = "Portapapeles"
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Mostrar historial", action: #selector(togglePopover), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Limpiar historial", action: #selector(clearHistory), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Salir", action: #selector(quit), keyEquivalent: "q")

        for item in menu.items {
            item.target = self
        }
        statusItem.menu = menu
    }

    private func clipboardIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()

        let body = NSBezierPath(roundedRect: NSRect(x: 3, y: 1, width: 12, height: 15), xRadius: 2, yRadius: 2)
        NSColor.labelColor.setStroke()
        body.lineWidth = 1.5
        body.stroke()

        let clip = NSBezierPath(roundedRect: NSRect(x: 6, y: 13, width: 6, height: 3), xRadius: 1, yRadius: 1)
        clip.lineWidth = 1.5
        clip.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
    
    private func setupPopover() {
        let vc = PopoverViewController(historyManager: historyManager)
        popover.contentViewController = vc
        popover.behavior = .transient
        popover.animates = true
    }
    
    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Hacer que el popover sea el foco
            if let window = popover.contentViewController?.view.window {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
    }

    @objc private func clearHistory() {
        historyManager.clearAll()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}