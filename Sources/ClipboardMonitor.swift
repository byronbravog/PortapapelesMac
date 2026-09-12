import Cocoa

class ClipboardMonitor {
    private var changeCount: Int = 0
    private var timer: Timer?
    private let onNewCopy: (ClipboardItem) -> Void
    
    init(onNewCopy: @escaping (ClipboardItem) -> Void) {
        self.onNewCopy = onNewCopy
        startMonitoring()
    }
    
    func startMonitoring() {
        let pasteboard = NSPasteboard.general
        changeCount = pasteboard.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let currentCount = pasteboard.changeCount
            if currentCount != self.changeCount {
                self.changeCount = currentCount
                
                if let content = pasteboard.string(forType: .string), !content.isEmpty {
                    self.onNewCopy(ClipboardItem(kind: .text, value: content))
                }
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stopMonitoring()
    }
}