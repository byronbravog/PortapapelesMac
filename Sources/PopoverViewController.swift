import Cocoa

class PopoverViewController: NSViewController {
    private let historyManager: HistoryManager
    private var filteredItems: [ClipboardItem] = []
    
    private let searchField: NSSearchField = {
        let field = NSSearchField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholderString = "Buscar en el historial..."
        field.bezelStyle = .roundedBezel
        return field
    }()
    
    private let tableView: NSTableView = {
        let table = NSTableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        table.usesAlternatingRowBackgroundColors = true
        table.backgroundColor = .clear
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("textColumn"))
        column.title = ""
        column.width = 400
        table.addTableColumn(column)
        table.headerView = nil
        
        return table
    }()
    
    private let scrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        return scroll
    }()
    
    init(historyManager: HistoryManager) {
        self.historyManager = historyManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) no soportado")
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 300))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        view.layer?.cornerRadius = 12
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTable()
        loadHistory()
        
        // Observar cambios
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(historyDidChange),
            name: HistoryManager.historyChangedNotification,
            object: historyManager
        )
    }
    
    private func setupUI() {
        // Buscar
        view.addSubview(searchField)
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
        searchField.target = self
        searchField.action = #selector(searchFieldChanged)
        
        // Tabla
        scrollView.documentView = tableView
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 28
        tableView.target = self
        tableView.doubleAction = #selector(doubleClickRow)
        
        // Teclas de navegación
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.view.window?.isKeyWindow == true else { return event }
            
            if event.keyCode == 53 { // Escape
                self.dismiss(nil)
                return nil
            }
            
            if event.keyCode == 36 { // Enter
                self.pasteSelectedItem()
                return nil
            }
            
            return event
        }
    }
    
    @objc func loadHistory() {
        filteredItems = historyManager.getItems(filter: searchField.stringValue)
        tableView.reloadData()
    }
    
    @objc func historyDidChange() {
        loadHistory()
    }
    
    @objc func searchFieldChanged() {
        let filter = searchField.stringValue
        if filter.isEmpty {
            filteredItems = historyManager.getItems()
        } else {
            filteredItems = historyManager.getItems(filter: filter)
        }
        tableView.reloadData()
    }
    
    @objc func doubleClickRow() {
        pasteSelectedItem()
    }
    
    private func pasteSelectedItem() {
        let row = tableView.selectedRow
        guard row >= 0 && row < filteredItems.count else { return }
        
        let selected = filteredItems[row]
        
        NSPasteboard.general.clearContents()
        if let imageData = selected.imageData {
            NSPasteboard.general.setData(imageData, forType: .tiff)
        } else {
            NSPasteboard.general.setString(selected.value, forType: .string)
        }
        
        // Simular Cmd+V
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        
        keyVDown?.flags = .maskCommand
        keyVUp?.flags = .maskCommand
        
        keyVDown?.post(tap: .cghidEventTap)
        keyVUp?.post(tap: .cghidEventTap)
        
        // Cerrar popover
        (NSApp.delegate as? AppDelegate)?.closePopover()
    }
}

extension PopoverViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredItems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("cell")
        let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView ?? {
            let newCell = NSTableCellView()
            newCell.identifier = identifier
            newCell.textField = {
                let field = NSTextField()
                field.isBordered = false
                field.isEditable = false
                field.drawsBackground = false
                field.font = .systemFont(ofSize: 13)
                field.lineBreakMode = .byTruncatingTail
                field.translatesAutoresizingMaskIntoConstraints = false
                newCell.addSubview(field)
                
                NSLayoutConstraint.activate([
                    field.leadingAnchor.constraint(equalTo: newCell.leadingAnchor, constant: 8),
                    field.trailingAnchor.constraint(equalTo: newCell.trailingAnchor, constant: -8),
                    field.centerYAnchor.constraint(equalTo: newCell.centerYAnchor)
                ])
                
                return field
            }()
            return newCell
        }()
        
        cell.textField?.stringValue = filteredItems[row].displayText
        return cell
    }
}