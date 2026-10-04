//
//  iTermSettingsViewFactory.swift
//  iTerm2
//
//  Builders that construct Settings controls in code the way Interface Builder
//  decodes them from PreferencePanel.xib, so pane builders read as lists of
//  controls. Part of the xib-to-code migration of Settings panes.

import AppKit

@objc(iTermSettingsViewFactory)
class iTermSettingsViewFactory: NSObject {
    @objc static func checkbox(frame: NSRect,
                               title: String,
                               toolTip: String?,
                               autoresizingMask: NSView.AutoresizingMask,
                               target: AnyObject?,
                               action: Selector?) -> NSButton {
        let button = NSButton(frame: frame)
        button.setButtonType(.switch)
        button.bezelStyle = .regularSquare
        button.imagePosition = .imageLeft
        button.alignment = .left
        button.state = .on
        button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        button.title = title
        button.toolTip = toolTip
        button.autoresizingMask = autoresizingMask
        button.target = target
        button.action = action
        return button
    }

    @objc static func label(frame: NSRect,
                            title: String,
                            alignment: NSTextAlignment,
                            autoresizingMask: NSView.AutoresizingMask) -> NSTextField {
        let field = NSTextField(frame: frame)
        field.stringValue = title
        field.isEditable = false
        field.isSelectable = false
        field.isBezeled = false
        field.isBordered = false
        field.drawsBackground = false
        field.textColor = .labelColor
        field.backgroundColor = .textBackgroundColor
        field.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        field.alignment = alignment
        if let cell = field.cell as? NSTextFieldCell {
            cell.lineBreakMode = .byClipping
            cell.wraps = false
            cell.isScrollable = false
        }
        field.focusRingType = .none
        field.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 251), for: .horizontal)
        field.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 750), for: .vertical)
        field.autoresizingMask = autoresizingMask
        return field
    }

    @objc static func smallSquareButton(frame: NSRect,
                                        title: String,
                                        image: NSImage?,
                                        autoresizingMask: NSView.AutoresizingMask,
                                        target: AnyObject?,
                                        action: Selector?) -> NSButton {
        let button = NSButton(frame: frame)
        button.setButtonType(.momentaryPushIn)
        button.bezelStyle = .smallSquare
        button.isBordered = true
        button.title = title
        button.image = image
        button.imagePosition = .imageOverlaps
        button.imageScaling = .scaleProportionallyDown
        button.alignment = .center
        button.state = .on
        button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        button.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 750), for: .vertical)
        button.autoresizingMask = autoresizingMask
        button.target = target
        button.action = action
        return button
    }
}
