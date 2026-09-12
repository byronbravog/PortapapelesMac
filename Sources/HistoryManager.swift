import Cocoa

struct ClipboardItem: Codable, Equatable {
    enum Kind: String, Codable {
        case text
        case image
    }

    let kind: Kind
    let value: String

    var displayText: String {
        switch kind {
        case .text:
            return value
        case .image:
            return "Imagen copiada"
        }
    }

    var imageData: Data? {
        kind == .image ? Data(base64Encoded: value) : nil
    }
}

class HistoryManager {
    static let historyChangedNotification = Notification.Name("HistoryChanged")

    private var items: [ClipboardItem] = []
    private let maxItems: Int = 200
    private let savePath: URL
    
    init() {
        // Guardar en ~/Library/Application Support/Portapapeles/
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("Portapapeles")
        
        // Crear carpeta si no existe
        if !FileManager.default.fileExists(atPath: appFolder.path) {
            try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        
        savePath = appFolder.appendingPathComponent("history.json")
        loadHistory()
    }
    
    func addItem(_ item: ClipboardItem) {
        // Evitar duplicados exactos consecutivos
        if let last = items.first, last == item {
            return
        }
        
        // Si ya existe, moverlo al principio
        if let existingIndex = items.firstIndex(of: item) {
            items.remove(at: existingIndex)
        }
        
        items.insert(item, at: 0)
        
        if items.count > maxItems {
            items.removeLast()
        }
        
        saveHistory()
        postHistoryChanged()
    }

    func getItems(filter: String = "") -> [ClipboardItem] {
        if filter.isEmpty {
            return items
        }
        return items.filter { $0.displayText.localizedCaseInsensitiveContains(filter) }
    }
    
    func deleteItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
        saveHistory()
        postHistoryChanged()
    }
    
    func clearAll() {
        items.removeAll()
        saveHistory()
        postHistoryChanged()
    }
    
    func clearUnpinned() {
        // En una versión completa, tendrías un sistema de pinned
        // Por ahora, eliminamos todos los items
        clearAll()
    }
    
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: savePath)
        } catch {
            print("Error guardando historial: \(error)")
        }
    }

    private func postHistoryChanged() {
        NotificationCenter.default.post(name: Self.historyChangedNotification, object: self)
    }
    
    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: savePath.path) else {
            items = []
            return
        }
        
        do {
            let data = try Data(contentsOf: savePath)
            items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            do {
                let data = try Data(contentsOf: savePath)
                let oldItems = try JSONDecoder().decode([String].self, from: data)
                items = oldItems.map { ClipboardItem(kind: .text, value: $0) }
            } catch {
                print("Error cargando historial: \(error)")
                items = []
            }
        }
    }
}