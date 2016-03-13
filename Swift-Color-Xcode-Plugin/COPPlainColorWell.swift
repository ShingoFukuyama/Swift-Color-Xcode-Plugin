//
//  SWCPlainColorWell.swift
//  Swift-Color-Xcode-Plugin
//
//  Created by Shingo Fukuyama on 3/13/16.
//  Copyright © 2016 Shingo Fukuyama. All rights reserved.
//

import Foundation
import Cocoa

class SWCPlainColorWell : NSColorWell {
    var strokeColor : NSColor? = NSColor.whiteColor()
    
    override func deactivate() {
        super.deactivate()
        NSColorPanel.sharedColorPanel().orderOut(nil)
    }
    
    override func drawRect(dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        let rectBody = NSMakeRect(0, -5, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) + 5)
        let path = NSBezierPath.init(roundedRect: rectBody, xRadius: 5.0, yRadius: 5.0)
        path.addClip()
        self.drawWellInside(self.bounds)
        NSGraphicsContext.restoreGraphicsState()
        
        if let color = self.strokeColor {
            let strokePath = NSBezierPath.init(roundedRect: NSInsetRect(rectBody, 0.5, 0.5), xRadius: 5.0, yRadius: 5.0)
            color.setStroke()
            strokePath.stroke()
        }
    }
}

