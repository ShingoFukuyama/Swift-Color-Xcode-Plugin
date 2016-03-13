//
//  SWCColorFrameView.swift
//  Swift-Color-Xcode-Plugin
//
//  Created by Shingo Fukuyama on 3/13/16.
//  Copyright © 2016 Shingo Fukuyama. All rights reserved.
//

import Foundation
import Cocoa


class SWCColorFrameView : NSView {
    var color:NSColor? = NSColor.whiteColor()
    
    override func drawRect(dirtyRect: NSRect) {
        if let col = self.color {
            col.setStroke()
            NSBezierPath.strokeRect(NSInsetRect(self.bounds, 0.5, 0.5))
        }
    }
}
