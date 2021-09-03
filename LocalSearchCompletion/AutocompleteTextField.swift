//
//  AutocompleteTextField.swift
//  AutocompleteTextField
//
//  Created by Nikhil Nigade on 03/09/21.
//

import Cocoa

@objc
protocol AutocompleteTextFieldDelegate: NSTextFieldDelegate {
    
    @objc
    optional func didSelectItem(_ item: Any)
    
}

class AutocompleteTextField: NSTextField {
    
    // Popover Properties
    @IBInspectable var popoverWidth: CGFloat = 200
    @IBInspectable var popoverWidthMatchesTextField: Bool = true
    var popoverPadding: NSDirectionalEdgeInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
    @IBInspectable var maxResults: Int = 10
    
    var autoCompletePopover:NSPopover?
    weak var autoCompleteTableView:NSTableView?
    
    weak var autocompleteDelegate: AutocompleteTextFieldDelegate?
    
    var matches: [Any] = [] {
        didSet {
            
            if matches.count > 0 {
                let index = 0
                autoCompleteTableView?.reloadData()
                autoCompleteTableView?.scrollRowToVisible(index)
                
                let rect = self.visibleRect
                autoCompletePopover?.show(relativeTo: rect, of: self, preferredEdge: NSRectEdge.maxY)
            }
            else {
                autoCompletePopover?.close()
            }
            
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        delegate = self
        
        if popoverWidthMatchesTextField {
            popoverWidth = self.bounds.width
        }
        
        let column1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("text"))
        column1.isEditable = false
        column1.width = popoverWidth - popoverPadding.leading - popoverPadding.trailing
        
        let tableView = NSTableView(frame: NSZeroRect)
        tableView.selectionHighlightStyle = NSTableView.SelectionHighlightStyle.regular
        tableView.backgroundColor = NSColor.clear
        tableView.rowSizeStyle = NSTableView.RowSizeStyle.small
        tableView.intercellSpacing = NSMakeSize(10.0, 0.0)
        tableView.headerView = nil
        tableView.refusesFirstResponder = true
        tableView.target = self
        tableView.doubleAction = #selector(insert(_:))
        
        tableView.addTableColumn(column1)
        tableView.delegate = self
        tableView.dataSource = self
        
        self.autoCompleteTableView = tableView
        
        let tableSrollView = NSScrollView(frame: NSZeroRect)
        tableSrollView.drawsBackground = false
        tableSrollView.documentView = tableView
        tableSrollView.hasVerticalScroller = true
        
        // popover throws when contentView's height=0
        let contentView:NSView = NSView(frame: NSRect.init(x: 0, y: 0, width: popoverWidth, height: 1))
        contentView.addSubview(tableSrollView)
        
        let contentViewController = NSViewController()
        contentViewController.view = contentView
        
        let popover = NSPopover()
        popover.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
        popover.animates = false
        popover.contentViewController = contentViewController
        popover.delegate = self
        
        self.autoCompletePopover = popover
        
    }
    
    // MARK: Range Persistence
    fileprivate var aboutToShowPopover: Bool = false
    fileprivate var savedSelectedRanges: [NSValue]?
    
    override func becomeFirstResponder() -> Bool {

        if super.becomeFirstResponder() == true {
            
            if self.aboutToShowPopover {
                
                if let ranges = self.savedSelectedRanges {
                    
                    if let fieldEditor = self.currentEditor() as? NSTextView {
                        fieldEditor.insertText("", replacementRange: NSRange(location: 0, length:0))
                        fieldEditor.selectedRanges = ranges
                    }
                    
                }
                
            }
            return true
        }

        return false
        
    }
    
    override func textShouldEndEditing(_ textObject: NSText) -> Bool {
        
        if super.textShouldEndEditing(textObject) {
            
            if self.aboutToShowPopover {
                
                let fieldEditor = textObject as! NSTextView
                self.savedSelectedRanges = fieldEditor.selectedRanges
                return true
                
            }
            
        }
        return false
    }
    
    // MARK:
    @objc func insert(_ sender:AnyObject) {
        let selectedRow = self.autoCompleteTableView!.selectedRow
        let matchCount = self.matches.count
        
        guard selectedRow >= 0, selectedRow < matchCount else {
            return
        }
        
        self.stringValue = String(describing: self.matches[selectedRow])
        
        if let autocompleteDelegate = autocompleteDelegate {
            DispatchQueue.main.async {
                autocompleteDelegate.didSelectItem?(self.matches[selectedRow])
            }
        }
        
        self.autoCompletePopover?.close()
    }
    
    override func complete(_ sender: Any?) {
        
        let lengthOfWord = self.stringValue.count
        let subStringRange = NSMakeRange(0, lengthOfWord)
        
        //This happens when we just started a new word or if we have already typed the entire word
        if subStringRange.length == 0 || lengthOfWord == 0 {
            self.autoCompletePopover?.close()
            return
        }
        
        if matches.count == 0 {
            autoCompletePopover?.close()
        }
        
    }
    
}

// MARK: - NSPopoverDelegate
extension AutocompleteTextField: NSPopoverDelegate {
    
    // caclulate contentSize only before it will show, to make it more stable
    func popoverWillShow(_ notification: Notification) {
        
        guard let popover = notification.object as? NSPopover,
              let autoCompleteTableView = autoCompleteTableView else {
            return
        }
        
        let numberOfRows = min(autoCompleteTableView.numberOfRows, maxResults)
        let height = (autoCompleteTableView.rowHeight + autoCompleteTableView.intercellSpacing.height) * CGFloat(numberOfRows) + 2 * 0.0
        let frame = NSRect(x: 0, y: 0, width: popoverWidth, height: height)
        autoCompleteTableView.enclosingScrollView?.frame = frame.insetBy(dx: popoverPadding.leading + popoverPadding.trailing, dy: popoverPadding.top + popoverPadding.bottom)
        popover.contentSize = NSMakeSize(NSWidth(frame), NSHeight(frame))
        
        aboutToShowPopover = true
        
        DispatchQueue.main.async {
            let _ = self.becomeFirstResponder()
        }
        
    }
    
}

// MARK: - NSTableViewDataSource
extension AutocompleteTextField : NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return matches.count
    }
    
}

// MARK: - NSTableViewDelegate
extension AutocompleteTextField : NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return AutocompleteTableRowView()
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("autocompleteTableViewCell"), owner: self) as? NSTableCellView
        
        if cellView == nil {
            
            cellView = NSTableCellView(frame: NSZeroRect)
            
            let textField = NSTextField(frame: NSZeroRect)
            textField.isBezeled = false
            textField.drawsBackground = false
            textField.isEditable = false
            textField.isSelectable = false
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.cell?.lineBreakMode = .byTruncatingTail
            textField.cell?.truncatesLastVisibleLine = true
            
            cellView!.addSubview(textField)
            cellView!.textField = textField
            
            cellView!.identifier = NSUserInterfaceItemIdentifier("autocompleteTableViewCell")
            
            NSLayoutConstraint.activate([
                textField.heightAnchor.constraint(equalToConstant: 16),
                textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor)
            ])
            
        }
        
        let attrs: [NSAttributedString.Key: AnyHashable] = [
            .foregroundColor: NSColor.selectedTextColor,
            .font: NSFont.systemFont(ofSize: 13)
        ]
        
        let mutableAttriStr = NSMutableAttributedString(string: String(describing: self.matches[row]), attributes: attrs)
        
        cellView!.textField!.attributedStringValue = mutableAttriStr
        
        return cellView
    }
}

extension AutocompleteTextField: NSTextFieldDelegate {
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        
        guard let tableView = autoCompleteTableView else {
            return false
        }
        
        let isShown = autoCompletePopover?.isShown ?? false
        
        switch commandSelector {
        case #selector(moveUp(_:)):
            
            if isShown {
                tableView.selectRowIndexes(IndexSet(integer: tableView.selectedRow - 1), byExtendingSelection: false)
                tableView.scrollRowToVisible(tableView.selectedRow)
                return true
            }
            
        case #selector(moveDown(_:)):
            
            if isShown {
                tableView.selectRowIndexes(IndexSet(integer: tableView.selectedRow + 1), byExtendingSelection: false)
                tableView.scrollRowToVisible(tableView.selectedRow)
                return true
            }
            
        case #selector(insertNewline(_:)):
            self.insert(self)
            return true
        case #selector(cancelOperation(_:)),
            NSSelectorFromString("cancel:"):
            if isShown {
                self.autoCompletePopover?.close()
            }
            return false // we also want the default behaviour
        default:
            
            return autocompleteDelegate?.control?(control, textView: textView, doCommandBy: commandSelector) ?? false
            
        }
        
        return false
        
    }
    
}
