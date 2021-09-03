//
//  AutocompleteTableRowView.swift
//  AutocompleteTableRowView
//
//  Created by Nikhil Nigade on 03/09/21.
//

import Cocoa

class AutocompleteTableRowView : NSTableRowView {
    
    override func drawSelection(in dirtyRect: NSRect) {
        
        if self.selectionHighlightStyle != .none {
            
            let selectionRect = self.bounds.insetBy(dx: 0.5, dy: 0.5)
            
            NSColor.selectedControlColor.setStroke()
            NSColor.selectedControlColor.setFill()
            
            let selectionPath = NSBezierPath(roundedRect: selectionRect, xRadius: 0.0, yRadius: 0.0)
            
            selectionPath.fill()
            selectionPath.stroke()
        }
        
    }
    
    override var interiorBackgroundStyle : NSView.BackgroundStyle {
        get {
            if self.isSelected {
                return NSView.BackgroundStyle.emphasized
            }
            else{
                return NSView.BackgroundStyle.normal
            }
        }
    }
}
