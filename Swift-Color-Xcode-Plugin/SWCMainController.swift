//
//  SWCMainController.swift
//  Swift-Color-Xcode-Plugin
//
//  Created by Shingo Fukuyama on 3/13/16.
//  Copyright © 2016 Shingo Fukuyama. All rights reserved.
//

import Foundation
import Cocoa

private struct SWC_KEY {
    static let HighlightingDisabled = "SWCColorHelperHighlightingDisabled"
    static let InsertionMode = "SWCColorHelperInsertionMode"
}

private struct SWC_RGBA {
    var r: CGFloat = 1.0
    var g: CGFloat = 1.0
    var b: CGFloat = 1.0
    var a: CGFloat = 1.0
    init(r: Double, g: Double, b: Double, a: Double) {
        (self.r, self.g, self.b, self.a) = (CGFloat(a), CGFloat(g), CGFloat(b), CGFloat(a))
    }
}

enum SWCColorType : Int, Comparable {
    case None = 0
     // iOS
    case UIRGBA                   //UIColor(red:1.0, green:0.0, blue:0.0, alpha:1.0)
    case UIRGBAInit               //UIColor.init(red:1.0, green:0.0, blue:0.0, alpha:1.0)
    case UIWhite                  //UIColor(white:0.5, alpha:1.0)
    case UIWhiteInit              //UIColor.init(white:0.5, alpha:1.0)
    case UIConstant               //UIColor.redColor()
    // Mac OS X
    case NSRGBA                   //NSColor(red:1.0, green:0.0, blue:0.0, alpha:1.0)
    case NSRGBAInit               //NSColor.init(red:1.0, green:0.0, blue:0.0, alpha:1.0)
    case NSRGBADevice             //NSColor(deviceRed:1.0, green:0.0, blue:0.0, alpha:1.0)
    case NSRGBADeviceInit         //NSColor.init(deviceRed:1.0, green:0.0, blue:0.0, alpha:1.0)
    case NSRGBACalibrated         //NSColor(calibratedRed:1.0, green:0.0, blue:0.0, alpha:1.0)
    case NSRGBACalibratedInit     //NSColor.init(calibratedRed:1.0, green:0.0, blue:0.0, alpha:1.0)
    case NSWhite                  //NSColor(white:0.5, alpha:1.0)
    case NSWhiteInit              //NSColor.init(white:0.5, alpha:1.0)
    case NSWhiteDevice            //NSColor(deviceWhite:0.5, alpha:1.0)
    case NSWhiteDeviceInit        //NSColor.init(deviceWhite:0.5, alpha:1.0)
    case NSWhiteCalibrated        //NSColor(calibratedWhite:0.5, alpha:1.0)
    case NSWhiteCalibratedInit    //NSColor.init(calibratedWhite:0.5, alpha:1.0)
    case NSConstant               //NSColor.redColor()
    static func isNSColor(colorType: SWCColorType) -> Bool {
        return colorType >= .NSRGBA
    }
}
func < (lhs:SWCColorType, rhs:SWCColorType) -> Bool { return lhs.rawValue < rhs.rawValue }


class SWCMainController : NSObject {
    lazy var notificationCenter = NSNotificationCenter.defaultCenter()
    lazy var userDefault = NSUserDefaults.standardUserDefaults()
    let colorWell = SWCPlainColorWell.init(frame: NSMakeRect(0, 0, 50, 30))
    var colorFrameView = SWCColorFrameView.init(frame: NSZeroRect)
    var textView: NSTextView? {
            if let fr = NSApp.keyWindow?.firstResponder as? NSTextView {
                return fr
            }
            return nil
    }
    var selectedColorType = SWCColorType.None
    var selectedColorRange = NSMakeRange(NSNotFound, 0)
    let constantColorsByName: [String:NSColor]
    = [
        "black"     : NSColor.blackColor(),
        "darkGray"  : NSColor.darkGrayColor(),
        "gray"      : NSColor.grayColor(),
        "lightGray" : NSColor.lightGrayColor(),
        "white"     : NSColor.whiteColor(),
        "red"       : NSColor.redColor(),
        "green"     : NSColor.greenColor(),
        "blue"      : NSColor.blueColor(),
        "cyan"      : NSColor.cyanColor(),
        "yellow"    : NSColor.yellowColor(),
        "magenta"   : NSColor.magentaColor(),
        "orange"    : NSColor.orangeColor(),
        "purple"    : NSColor.purpleColor(),
        "brown"     : NSColor.brownColor(),
        "clear"     : NSColor.clearColor()
    ]
    
    let rgbaUIColorRegex = try! NSRegularExpression.init(pattern: "UIColor(\\.init)?\\(\\s*red\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\,\\s*green\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\,\\s*blue\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\,\\s*alpha\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\)", options: NSRegularExpressionOptions.init(rawValue: 0))
    let whiteUIColorRegex = try! NSRegularExpression.init(pattern: "UIColor(\\.init)?\\(\\s*white\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\,\\s*alpha\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\)", options: NSRegularExpressionOptions.init(rawValue: 0))
    let rgbaNSColorRegex = try! NSRegularExpression.init(pattern: "NSColor(\\.init)?\\(\\s*(calibrated|device)?[rR]ed\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\,\\s*green\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\,\\s*blue\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\,\\s*alpha\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\)", options: NSRegularExpressionOptions.init(rawValue: 0))
    let whiteNSColorRegex = try! NSRegularExpression.init(pattern: "NSColor(\\.init)?\\(\\s*(calibrated|device)?[wW]hite\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\,\\s*alpha\\s*\\:\\s*([0-9]*\\.?[0-9]*)\\s*(\\/\\s*[0-9]*\\.?[0-9]*)?\\s*\\)", options: NSRegularExpressionOptions.init(rawValue: 0))
    let constantColorRegex = try! NSRegularExpression.init(pattern: "(UI|NS)Color\\.(black|darkGray|lightGray|white|gray|red|green|blue|cyan|yellow|magenta|orange|purple|brown|clear)Color\\(\\s*\\)", options: NSRegularExpressionOptions.init(rawValue: 0))
    
    static let sharedInstance : SWCMainController = {
        let instance = SWCMainController.init()
        return instance
    }()
    
    private override init() {
        super.init()
        
        notificationCenter.addObserver(self, selector: "applicationDidFinishLaunching:", name: NSApplicationDidFinishLaunchingNotification, object: nil)
        
        self.colorWell.target = self
        self.colorWell.action = "colorDidChange:"
        
    }
    
    func createMenuItem() {
        if let item = NSApp.mainMenu?.itemWithTitle("Edit"),
            let submenu = item.submenu {
                submenu.addItem(NSMenuItem.separatorItem())
                let toggleColorHeighlightMenuItem = NSMenuItem.init(title: "Show Colors Under Caret", action: "toggleColorHeighlightingEnabled", keyEquivalent: "")
                toggleColorHeighlightMenuItem.target = self
                submenu.addItem(toggleColorHeighlightMenuItem)
                let colorInsertionModeItem = NSMenuItem.init(title: "Color Insertion Mode", action: nil, keyEquivalent: "")
                let colorInsertionModeNSItem = NSMenuItem.init(title: "NSColor", action: "selectNSColorInsertionMode:", keyEquivalent: "")
                colorInsertionModeNSItem.target = self
                colorInsertionModeItem.target = self
                let colorInsertionModeUIItem = NSMenuItem.init(title: "UIColor", action: "selectUIColorInsertionMode:", keyEquivalent: "")
                colorInsertionModeUIItem.target = self
                
                let colorInsertionModeMenu = NSMenu.init(title: "Color Insertion Mode")
                colorInsertionModeItem.submenu = colorInsertionModeMenu
                colorInsertionModeItem.submenu!.addItem(colorInsertionModeUIItem)
                colorInsertionModeItem.submenu!.addItem(colorInsertionModeNSItem)
                submenu.addItem(colorInsertionModeItem)
                
                let insertColorMenuItem = NSMenuItem.init(title: "Insert Color...", action: "insertColor:", keyEquivalent: "")
                insertColorMenuItem.target = self
                submenu.addItem(insertColorMenuItem)
        }
    }
    
    class func pluginDidLoad(plugin: NSBundle) {
        self.sharedInstance
    }

    func applicationDidFinishLaunching(notification: NSNotification) {
        self.createMenuItem()
        
        let highlightingEnabled = !NSUserDefaults.standardUserDefaults().boolForKey(SWC_KEY.HighlightingDisabled)
        if highlightingEnabled {
            self.activateColorHighlighting()
        }
    }
    
    
    // MARK: Preferences
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.action.description {
        case "insertColor:":
            return self.textView != nil
        case "toggleColorHighlightingEnabled:":
            let enabled = userDefault.boolForKey(SWC_KEY.HighlightingDisabled)
            menuItem.state = enabled ? NSOffState : NSOnState
        case "selectNSColorInsertionMode:":
            let state = userDefault.integerForKey(SWC_KEY.InsertionMode)
            menuItem.state = state == 1 ? NSOnState : NSOffState
        case "selectUIColorInsertionMode:":
            let state = userDefault.integerForKey(SWC_KEY.InsertionMode)
            menuItem.state = state == 0 ? NSOnState : NSOffState
        default: break
        }
        return true
    }
    
    func selectNSColorInsertionMode(sender: AnyObject) {
        userDefault.setInteger(1, forKey: SWC_KEY.InsertionMode)
        userDefault.synchronize()
    }
    
    func selectUIColorInsertionMode(sender: AnyObject) {
        userDefault.setInteger(0, forKey: SWC_KEY.InsertionMode)
        userDefault.synchronize()
    }
    
    func toggleColorHighlightingEnabled(sender: AnyObject) {
        let enabled = userDefault.boolForKey(SWC_KEY.HighlightingDisabled)
        userDefault.setBool(!enabled, forKey: SWC_KEY.HighlightingDisabled)
        userDefault.synchronize()
        if enabled {
            self.activateColorHighlighting()
        }
        else {
            self.deactivateColorHighlighting()
        }
    }
    
    func activateColorHighlighting() {
        notificationCenter.addObserver(self, selector: "selectionDidChange:", name: NSTextViewDidChangeSelectionNotification, object: nil)
        let notification = NSNotification.init(name: NSTextViewDidChangeSelectionNotification, object: nil)
        self.selectionDidChange(notification)
    }
    
    func deactivateColorHighlighting() {
        notificationCenter.removeObserver(self, name: NSTextViewDidChangeSelectionNotification, object: nil)
        self.dismissColorWell()
    }
    
    
    // MARK: Color Insertion
    func insertColor(sender: AnyObject) {
        guard let textView = self.textView else {
            return NSBeep()
        }
        if userDefault.boolForKey(SWC_KEY.HighlightingDisabled) {
            userDefault.setBool(false, forKey: SWC_KEY.HighlightingDisabled)
            userDefault.synchronize()
            self.activateColorHighlighting()
        }
        textView.undoManager?.beginUndoGrouping()
        let insertionMode = userDefault.integerForKey(SWC_KEY.InsertionMode)
        let range = textView.selectedRange
        if insertionMode == 0 {
            textView.insertText("UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)", replacementRange:range)
        }
        else {
            textView.insertText("NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)", replacementRange:range)
        }
        textView.undoManager?.endUndoGrouping()
        self.performSelector("activateColorWell", withObject: nil, afterDelay: 0.0)
    }
    
    func activateColorWell() {
        self.colorWell.activate(true)
    }
    
    
    // MARK: Text Selection Handling
    func selectionDidChange(notification: NSNotification) {
        if userDefault.boolForKey(SWC_KEY.HighlightingDisabled) {
            return
        }
        guard let textView = self.textView where textView.selectedRanges.count != 0,
            let textStorage = textView.textStorage
            else {
                self.dismissColorWell()
                return
        }
        
        let selectedRange = textView.selectedRanges.first!.rangeValue
        let text = NSString(string: textStorage.string)
        let lineRange = text.lineRangeForRange(selectedRange)
        let selectedRangeInLine = NSMakeRange(selectedRange.location - lineRange.location, selectedRange.length)
        let line = text.substringWithRange(lineRange)
        
        var colorRange = NSMakeRange(NSNotFound, 0)
        var colorType = SWCColorType.None
        let _matchedColor = self.color(text: line, selectedRange: selectedRangeInLine, type: &colorType, matchedRange: &colorRange)
        guard let matchedColor = _matchedColor else {
            self.dismissColorWell()
            return
        }
        let backgroundColor = textView.backgroundColor.colorUsingColorSpace(NSColorSpace.genericRGBColorSpace())
        
        var c = SWC_RGBA(r: 1.0, g: 1.0, b: 1.0, a: 1.0)
        backgroundColor?.getRed(&c.r, green: &c.g, blue: &c.b, alpha: nil)
        let backgroundLuminance = (c.r + c.g + c.b) / 3.0
        
        let strokeColor = (backgroundLuminance > 0.5) ? NSColor.init(calibratedWhite: 0.2, alpha: 1.0) : NSColor.whiteColor()
        
        self.selectedColorType = colorType
        self.colorWell.color = matchedColor
        self.colorWell.strokeColor = strokeColor
        
        self.selectedColorRange = NSMakeRange(colorRange.location + lineRange.location, colorRange.length)
        let selectionRectOnScreen = textView.firstRectForCharacterRange(self.selectedColorRange, actualRange: nil)
        let selectionRectInWindow = textView.window!.convertRectFromScreen(selectionRectOnScreen)
        let selectionRectInView = textView.convertRect(selectionRectInWindow, fromView: nil)
        let colorWellRect = NSMakeRect(NSMaxX(selectionRectInView) - 49,
            NSMinY(selectionRectInView) - selectionRectInView.size.height - 2,
            50,
            selectionRectInView.size.height + 2)
        
        textView.addSubview(self.colorWell)
        self.colorWell.frame = NSIntegralRect(colorWellRect)
        
        self.colorFrameView.frame = NSInsetRect(NSIntegralRect(selectionRectInView), -1, -1)
        self.colorFrameView.color = strokeColor
        textView.addSubview(colorFrameView)
    }
    
    func dismissColorWell() {
        if self.colorWell.active {
            self.colorWell.deactivate()
            NSColorPanel.sharedColorPanel().orderOut(nil)
        }
        self.colorWell.removeFromSuperview()
        self.colorFrameView.removeFromSuperview()
        self.selectedColorRange = NSMakeRange(NSNotFound, 0)
        self.selectedColorType = .None
    }
    
    func colorDidChange(sender: AnyObject) {
        guard self.selectedColorRange.location != NSNotFound else {
            return
        }
        guard let textView = self.textView else {
            return
        }
        if let colorString = self.colorStringForColor(self.colorWell.color, colorType: self.selectedColorType) {
            textView.undoManager?.beginUndoGrouping()
            textView.insertText(colorString, replacementRange: self.selectedColorRange)
            textView.undoManager?.endUndoGrouping()
        }
    }
    
    
    // MARK: Color String Parsing
    func rangeCheckForColorMatch(range1: NSRange, _ range2: NSRange) -> Bool {
        return range1.location >= range2.location
            && NSMaxRange(range1) <= NSMaxRange(range2)
    }
    
    func color(text text: NSString, selectedRange: NSRange, inout type: SWCColorType, inout matchedRange: NSRange) -> NSColor? {
        var foundColor : NSColor? = nil
        var foundColorRange = NSMakeRange(NSNotFound, 0)
        var foundColorType = SWCColorType.None
        let textRange = NSMakeRange(0, text.length)
        let matchingOption = NSMatchingOptions.init(rawValue: 0)
        
        self.rgbaUIColorRegex.enumerateMatchesInString(String(text), options: matchingOption, range: textRange) { [unowned self] (result, flags, stop) in
            guard let res = result else {
                stop.memory = true
                return
            }
            let colorRange = res.range
            guard colorRange.location != NSNotFound else {
                stop.memory = true
                return
            }
            if self.rangeCheckForColorMatch(selectedRange, colorRange) {
                let hasInit = res.rangeAtIndex(1).location != NSNotFound
                var red = Double(text.substringWithRange(res.rangeAtIndex(2)))
                red = self.dividedValue(red!, divisorRange: res.rangeAtIndex(3), inString: text)
                var green = Double(text.substringWithRange(res.rangeAtIndex(4)))
                green = self.dividedValue(green!, divisorRange: res.rangeAtIndex(5), inString: text)
                var blue = Double(text.substringWithRange(res.rangeAtIndex(6)))
                blue = self.dividedValue(blue!, divisorRange: res.rangeAtIndex(7), inString: text)
                var alpha = Double(text.substringWithRange(res.rangeAtIndex(8)))
                alpha = self.dividedValue(alpha!, divisorRange: res.rangeAtIndex(9), inString: text)
                let c = SWC_RGBA.init(r: red!, g: green!, b: blue!, a: alpha!)
                foundColor = NSColor.init(calibratedRed: c.r, green: c.g, blue: c.b, alpha: c.a)
                if hasInit {
                    foundColorType = .UIRGBAInit
                }
                else {
                    foundColorType = .UIRGBA
                }
                foundColorRange = colorRange
                stop.memory = true
            }
        }
        
        if foundColor == nil {
            self.whiteUIColorRegex.enumerateMatchesInString(String(text), options: matchingOption, range: textRange) { (result, flags, stop) in
                guard let res = result else {
                    stop.memory = true
                    return
                }
                let colorRange = res.range
                guard colorRange.location != NSNotFound else {
                    stop.memory = true
                    return
                }
                if self.rangeCheckForColorMatch(selectedRange, colorRange) {
                    let hasInit = res.rangeAtIndex(1).location != NSNotFound
                    var white = Double(text.substringWithRange(res.rangeAtIndex(2)))
                    white = self.dividedValue(white!, divisorRange: res.rangeAtIndex(3), inString: text)
                    var alpha = Double(text.substringWithRange(res.rangeAtIndex(4)))
                    alpha = self.dividedValue(alpha!, divisorRange: res.rangeAtIndex(5), inString: text)
                    foundColor = NSColor(white: CGFloat(white!), alpha: CGFloat(alpha!))
                    foundColorType = hasInit ? .UIWhiteInit : .UIWhite
                    foundColorRange = colorRange
                    stop.memory = true
                }
            }
        }
        
        if foundColor == nil {
            self.constantColorRegex.enumerateMatchesInString(String(text), options: matchingOption, range: textRange) { [unowned self] (result, flags, stop) in
                guard let res = result else {
                    stop.memory = true
                    return
                }
                let colorRange = res.range
                guard colorRange.location != NSNotFound else {
                    stop.memory = true
                    return
                }
                if self.rangeCheckForColorMatch(selectedRange, colorRange) {
                    let NS_UI = text.substringWithRange(res.rangeAtIndex(1))
                    let colorName = text.substringWithRange(res.rangeAtIndex(2))
                    foundColor = self.constantColorsByName[colorName]
                    foundColorRange = colorRange
                    foundColorType = NS_UI.hasPrefix("UI") ? .UIConstant : .NSConstant
                    stop.memory = true
                }
            }
        }
        
        if foundColor == nil {
            self.rgbaNSColorRegex.enumerateMatchesInString(String(text), options: matchingOption, range: textRange) { [unowned self] (result, flags, stop) in
                guard let res = result else {
                    stop.memory = true
                    return
                }
                let colorRange = res.range
                guard colorRange.location != NSNotFound else {
                    stop.memory = true
                    return
                }
                if self.rangeCheckForColorMatch(selectedRange, colorRange) {
                    let hasInit = res.rangeAtIndex(1).location != NSNotFound
                    let foundPrefix = res.rangeAtIndex(2).location != NSNotFound
                    var red = Double(text.substringWithRange(res.rangeAtIndex(3)))
                    red = self.dividedValue(red!, divisorRange: res.rangeAtIndex(4), inString: text)
                    var green = Double(text.substringWithRange(res.rangeAtIndex(5)))
                    green = self.dividedValue(green!, divisorRange: res.rangeAtIndex(6), inString: text)
                    var blue = Double(text.substringWithRange(res.rangeAtIndex(7)))
                    blue = self.dividedValue(blue!, divisorRange: res.rangeAtIndex(8), inString: text)
                    var alpha = Double(text.substringWithRange(res.rangeAtIndex(9)))
                    alpha = self.dividedValue(alpha!, divisorRange: res.rangeAtIndex(10), inString: text)
                    let c = SWC_RGBA.init(r: red!, g: green!, b: blue!, a: alpha!)
                    if foundPrefix {
                        let prefixString = text.substringWithRange(res.rangeAtIndex(2))
                        if prefixString.hasPrefix("calibrated") {
                            foundColor = NSColor.init(calibratedRed: c.r, green: c.g, blue: c.b, alpha: c.a)
                            foundColorType = hasInit ? .NSRGBACalibratedInit : .NSRGBACalibrated
                        }
                        else {
                            foundColor = NSColor.init(deviceRed: c.r, green: c.g, blue: c.b, alpha: c.a)
                            foundColorType = hasInit ? .NSRGBADeviceInit : .NSRGBADevice
                        }
                    }
                    else {
                        foundColor = NSColor.init(red: c.r, green: c.g, blue: c.b, alpha: c.a)
                        foundColorType = hasInit ? .NSRGBAInit : .NSRGBA
                    }
                    
                    foundColorRange = colorRange
                    
                    stop.memory = true
                }
            }
        }
        
        if foundColor == nil {
            self.whiteNSColorRegex.enumerateMatchesInString(String(text), options: matchingOption, range: textRange) { (result, flags, stop) in
                guard let res = result else {
                    stop.memory = true
                    return
                }
                let colorRange = res.range
                guard colorRange.location != NSNotFound else {
                    stop.memory = true
                    return
                }
                if self.rangeCheckForColorMatch(selectedRange, colorRange) {
                    let hasInit = res.rangeAtIndex(1).location != NSNotFound
                    let hasPrefix = res.rangeAtIndex(2).location != NSNotFound
                    var white = Double(text.substringWithRange(res.rangeAtIndex(3)))
                    white = self.dividedValue(white!, divisorRange: res.rangeAtIndex(4), inString: text)
                    var alpha = Double(text.substringWithRange(res.rangeAtIndex(5)))
                    alpha = self.dividedValue(alpha!, divisorRange: res.rangeAtIndex(6), inString: text)
                    if hasPrefix {
                        let prefixString = text.substringWithRange(res.rangeAtIndex(2))
                        if prefixString.hasPrefix("calibrated") {
                            foundColor = NSColor(calibratedWhite: CGFloat(white!), alpha: CGFloat(alpha!))
                            foundColorType = hasInit ? .NSWhiteCalibratedInit : .NSWhiteCalibrated
                        }
                        else {
                            foundColor = NSColor(deviceWhite: CGFloat(white!), alpha: CGFloat(alpha!))
                            foundColorType = hasInit ? .NSWhiteDeviceInit : .NSWhiteDevice
                        }
                    }
                    else {
                        foundColor = NSColor(white: CGFloat(white!), alpha: CGFloat(alpha!))
                        foundColorType = hasInit ? .NSWhiteInit : .NSWhite
                    }
                    foundColorRange = colorRange
                    stop.memory = true
                }
            }
        }
        
        if foundColor != nil {
            matchedRange = foundColorRange
            type = foundColorType
            return foundColor
        }
        
        return nil
    }
    
    func dividedValue(var value: Double, divisorRange: NSRange, inString text: NSString) -> Double {
        if divisorRange.location != NSNotFound {
            let divisor = Double(text.substringWithRange(divisorRange).stringByTrimmingCharactersInSet(NSCharacterSet.init(charactersInString: "/ ")))!
            if divisor != 0 {
                value /= divisor
            }
        }
        return value
    }
    
    func colorStringForColor(var color: NSColor, colorType: SWCColorType) -> NSString? {
        var colorString : NSString? = nil
        var c = SWC_RGBA(r: -1, g: -1, b: -1, a: -1)
        color = color.colorUsingColorSpace(NSColorSpace.genericRGBColorSpace())!
        color.getRed(&c.r, green: &c.g, blue: &c.b, alpha: &c.a)
        if c.r >= 0 {
            for (colorName, constantColor) in self.constantColorsByName {
                if constantColor == color {
                    if SWCColorType.isNSColor(colorType) {
                        colorString = NSString(format: "NSColor.%@Color()", colorName)
                    }
                    else {
                        colorString = NSString(format: "UIColor.%@Color()", colorName)
                    }
                    break
                }
            }
            guard colorString == nil else {
                return colorString
            }
            if fabs(c.r - c.g) < 0.001 && fabs(c.g - c.b) < 0.001 {
                switch colorType {
                case .UIRGBA, .UIWhite, .UIConstant:
                    colorString = NSString(format:
                        "UIColor(white: %.3f, alpha: %.3f)", c.r, c.a)
                case .UIRGBAInit, .UIWhiteInit:
                    colorString = NSString(format:
                        "UIColor.init(white: %.3f, alpha: %.3f)", c.r, c.a)
                case .NSConstant, .NSRGBA, .NSWhite:
                    colorString = NSString(format:
                        "NSColor(white: %.3f, alpha: %.3f)", c.r, c.a)
                case .NSRGBAInit, .NSWhiteInit:
                    colorString = NSString(format:
                        "NSColor.init(white: %.3f, alpha: %.3f)", c.r, c.a)
                case .NSRGBACalibrated, .NSWhiteCalibrated:
                    colorString = NSString(format:
                        "NSColor(calibratedWhite: %.3f, alpha: %.3f)", c.r, c.a)
                case .NSRGBACalibratedInit, .NSWhiteCalibratedInit:
                    colorString = NSString(format:
                        "NSColor.init(calibratedWhite: %.3f, alpha: %.3f)", c.r, c.a)
                case .NSRGBADevice, .NSWhiteDevice:
                    colorString = NSString(format:
                        "NSColor(deviceWhite: %.3f, alpha: %.3f)", c.r, c.a)
                case .NSRGBADeviceInit, .NSWhiteDeviceInit:
                    colorString = NSString(format:
                        "NSColor.init(deviceWhite: %.3f, alpha: %.3f)", c.r, c.a)
                default: break
                }
            }
            else {
                switch colorType {
                case .UIRGBA, .UIWhite, .UIConstant:
                    colorString = NSString(format:
                        "UIColor(red: %.3f, green: %.3f, blue: %.3f, alpha: %.3f)", c.r, c.g, c.b, c.a)
                case .UIRGBAInit, .UIWhiteInit:
                    colorString = NSString(format:
                        "UIColor.init(red: %.3f, green: %.3f, blue: %.3f, alpha: %.3f)", c.r, c.g, c.b, c.a)
                case .NSConstant, .NSRGBA, .NSWhite:
                    colorString = NSString(format:
                        "NSColor(red: %.3f, green: %.3f, blue: %.3f, alpha: %.3f)", c.r, c.g, c.b, c.a)
                case .NSRGBAInit, .NSWhiteInit:
                    colorString = NSString(format:
                        "NSColor.init(red: %.3f, green: %.3f, blue: %.3f, alpha: %.3f)", c.r, c.g, c.b, c.a)
                case .NSRGBACalibrated, .NSWhiteCalibrated:
                    colorString = NSString(format:
                        "NSColor(calibratedRed: %.3f, green: %.3f, blue: %.3f, alpha: %.3f)", c.r, c.g, c.b, c.a)
                case .NSRGBACalibratedInit, .NSWhiteCalibratedInit:
                    colorString = NSString(format:
                        "NSColor.init(calibratedRed: %.3f, green: %.3f, blue: %.3f, alpha: %.3f)", c.r, c.g, c.b, c.a)
                case .NSRGBADevice, .NSWhiteDevice:
                    colorString = NSString(format:
                        "NSColor(deviceRed: %.3f, green: %.3f, blue: %.3f, alpha: %.3f)", c.r, c.g, c.b, c.a)
                case .NSRGBADeviceInit, .NSWhiteDeviceInit:
                    colorString = NSString(format:
                        "NSColor.init(deviceRed: %.3f, green: %.3f, blue: %.3f, alpha: %.3f)", c.r, c.g, c.b, c.a)
                default: break
                }
            }
        }
        return colorString
    }
    
}



