//
//  iTermSettingsViewDump.swift
//  iTerm2
//
//  Structural dump of a Settings pane's view hierarchy, used by the nib/code
//  comparison tests to prove a code-built pane matches its XIB.

import AppKit

final class iTermSettingsViewDump {
    private(set) var entries: [String: String] = [:]
    private var paths = [ObjectIdentifier: String]()

    init(root: NSView) {
        record(view: root, path: String(describing: type(of: root)))
    }

    func addBindings(of controller: iTermPreferencesBaseViewController) {
        let keyMap = controller.keyMap
        let enumerator = keyMap.keyEnumerator()
        while let control = enumerator.nextObject() as? NSView {
            guard let info = keyMap.object(forKey: control) as? PreferenceInfo else {
                continue
            }
            let related: String
            if let relatedView = info.relatedView,
               let relatedPath = paths[ObjectIdentifier(relatedView)] {
                related = relatedPath
            } else {
                related = "nil"
            }
            let value = "key=\(info.key ?? "nil") type=\(info.type.rawValue) related=\(related)"
            if let path = paths[ObjectIdentifier(control)] {
                entries["binding \(path)"] = value
            } else {
                entries["binding <unknown:\(String(describing: type(of: control)))>"] = value
            }
        }
    }

    var json: String {
        guard let data = try? JSONSerialization.data(withJSONObject: entries,
                                                     options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    static func differences(expected: iTermSettingsViewDump,
                            actual: iTermSettingsViewDump) -> [String] {
        let keys = Set(expected.entries.keys).union(actual.entries.keys).sorted()
        var lines = [String]()
        for key in keys {
            let left = expected.entries[key] ?? "<missing>"
            let right = actual.entries[key] ?? "<missing>"
            if left != right {
                lines.append("\(key): nib=\(left) code=\(right)")
            }
        }
        return lines.sorted()
    }

    private func set(_ path: String, _ property: String, _ value: String) {
        entries["\(path) \(property)"] = value
    }

    private static func className(of object: Any) -> String {
        return String(describing: type(of: object))
    }

    private static func describe(color: NSColor?) -> String {
        guard let color = color else {
            return "nil"
        }
        if color.type == .catalog {
            return "catalog:\(color.catalogNameComponent)/\(color.colorNameComponent)"
        }
        return String(describing: color)
    }

    private static func describe(font: NSFont?) -> String {
        guard let font = font else {
            return "nil"
        }
        return "\(font.fontName) \(font.pointSize)"
    }

    private func record(view: NSView, path: String) {
        paths[ObjectIdentifier(view)] = path
        set(path, "class", Self.className(of: view))
        set(path, "frame", NSStringFromRect(view.frame) as String)
        set(path, "autoresizingMask", String(view.autoresizingMask.rawValue))
        set(path, "translatesAutoresizingMaskIntoConstraints", String(view.translatesAutoresizingMaskIntoConstraints))
        set(path, "isHidden", String(view.isHidden))
        set(path, "alphaValue", String(describing: view.alphaValue))
        set(path, "toolTip", view.toolTip ?? "nil")
        set(path, "identifier", view.identifier?.rawValue ?? "nil")
        // The method form is imported as returning a non-optional String, but it
        // is nil for views without an identifier, so read it nil-safely.
        set(path, "accessibilityIdentifier", view.value(forKey: "accessibilityIdentifier") as? String ?? "nil")
        set(path, "contentHuggingHorizontal", String(describing: view.contentHuggingPriority(for: .horizontal).rawValue))
        set(path, "contentHuggingVertical", String(describing: view.contentHuggingPriority(for: .vertical).rawValue))
        set(path, "nextKeyView", view.nextKeyView.map { Self.className(of: $0) } ?? "nil")
        if #available(macOS 26, *) {
            set(path, "prefersCompactControlSizeMetrics", String(view.prefersCompactControlSizeMetrics))
        }

        if let control = view as? NSControl {
            set(path, "isEnabled", String(control.isEnabled))
            set(path, "tag", String(control.tag))
            set(path, "action", control.action.map { NSStringFromSelector($0) as String } ?? "nil")
            set(path, "target", control.target.map { Self.className(of: $0) } ?? "nil")
            set(path, "font", Self.describe(font: control.font))
            if let button = view as? NSButton {
                set(path, "alignment", String(button.alignment.rawValue))
            } else if let field = view as? NSTextField {
                set(path, "alignment", String(field.alignment.rawValue))
            }
            set(path, "controlSize", String(control.controlSize.rawValue))
            set(path, "isContinuous", String(control.isContinuous))
            if let cell = control.cell {
                set(path, "cellClass", Self.className(of: cell))
                set(path, "cellLineBreakMode", String(cell.lineBreakMode.rawValue))
                set(path, "cellSendsActionOnEndEditing", String(cell.sendsActionOnEndEditing))
                set(path, "cellWraps", String(cell.wraps))
                set(path, "cellIsScrollable", String(cell.isScrollable))
            } else {
                set(path, "cellClass", "nil")
            }
            if let binding = view.infoForBinding(.enabled) {
                let observed = binding[.observedObject].map { Self.className(of: $0) } ?? "nil"
                let keyPath = binding[.observedKeyPath] as? String ?? "nil"
                set(path, "enabledBinding", "\(observed) \(keyPath)")
            } else {
                set(path, "enabledBinding", "none")
            }
        }

        if let button = view as? NSButton {
            set(path, "title", button.title)
            set(path, "state", String(button.state.rawValue))
            set(path, "bezelStyle", String(button.bezelStyle.rawValue))
            set(path, "isBordered", String(button.isBordered))
            set(path, "imagePosition", String(button.imagePosition.rawValue))
            set(path, "imageScaling", String(button.imageScaling.rawValue))
            set(path, "image", button.image?.name().map { String(describing: $0) } ?? "nil")
            set(path, "keyEquivalent", button.keyEquivalent)
            if let buttonCell = button.cell as? NSButtonCell {
                set(path, "highlightsBy", String(buttonCell.highlightsBy.rawValue))
                set(path, "showsStateBy", String(buttonCell.showsStateBy.rawValue))
            }
        }

        if let field = view as? NSTextField {
            set(path, "stringValue", field.stringValue)
            set(path, "placeholderString", field.placeholderString ?? "nil")
            set(path, "isEditable", String(field.isEditable))
            set(path, "isSelectable", String(field.isSelectable))
            set(path, "isBezeled", String(field.isBezeled))
            set(path, "isBordered", String(field.isBordered))
            set(path, "drawsBackground", String(field.drawsBackground))
            set(path, "textColor", Self.describe(color: field.textColor))
            set(path, "backgroundColor", Self.describe(color: field.backgroundColor))
            set(path, "focusRingType", String(field.focusRingType.rawValue))
        }

        if let tabView = view as? NSTabView {
            set(path, "tabViewType", String(tabView.tabViewType.rawValue))
            set(path, "tabFont", Self.describe(font: tabView.font))
            set(path, "tabDelegate", tabView.delegate.map { Self.className(of: $0) } ?? "nil")
            set(path, "numberOfItems", String(tabView.tabViewItems.count))
            for (i, item) in tabView.tabViewItems.enumerated() {
                let itemPath = "\(path)/item[\(i)]"
                set(itemPath, "label", item.label)
                if let identifier = item.identifier {
                    set(itemPath, "identifier", String(describing: identifier))
                } else {
                    set(itemPath, "identifier", "nil")
                }
                if let itemView = item.view {
                    record(view: itemView, path: "\(itemPath)/view:\(Self.className(of: itemView))")
                }
            }
            return
        }

        if let scrollView = view as? NSScrollView {
            set(path, "borderType", String(scrollView.borderType.rawValue))
            set(path, "hasVerticalScroller", String(scrollView.hasVerticalScroller))
            set(path, "hasHorizontalScroller", String(scrollView.hasHorizontalScroller))
            set(path, "autohidesScrollers", String(scrollView.autohidesScrollers))
            set(path, "horizontalLineScroll", String(describing: scrollView.horizontalLineScroll))
            set(path, "horizontalPageScroll", String(describing: scrollView.horizontalPageScroll))
            set(path, "verticalLineScroll", String(describing: scrollView.verticalLineScroll))
            set(path, "verticalPageScroll", String(describing: scrollView.verticalPageScroll))
            set(path, "usesPredominantAxisScrolling", String(scrollView.usesPredominantAxisScrolling))
            set(path, "contentViewFrame", NSStringFromRect(scrollView.contentView.frame) as String)
            set(path, "contentViewDrawsBackground", String(scrollView.contentView.drawsBackground))
            set(path, "contentViewBackgroundColor", Self.describe(color: scrollView.contentView.backgroundColor))
            if let documentView = scrollView.documentView {
                record(view: documentView, path: "\(path)/document:\(Self.className(of: documentView))")
            }
            return
        }

        if let tableView = view as? NSTableView {
            set(path, "rowHeight", String(describing: tableView.rowHeight))
            set(path, "intercellSpacing", NSStringFromSize(tableView.intercellSpacing) as String)
            set(path, "columnAutoresizingStyle", String(tableView.columnAutoresizingStyle.rawValue))
            set(path, "allowsColumnReordering", String(tableView.allowsColumnReordering))
            set(path, "allowsColumnResizing", String(tableView.allowsColumnResizing))
            set(path, "allowsMultipleSelection", String(tableView.allowsMultipleSelection))
            set(path, "allowsEmptySelection", String(tableView.allowsEmptySelection))
            set(path, "autosaveTableColumns", String(tableView.autosaveTableColumns))
            set(path, "allowsExpansionToolTips", String(tableView.allowsExpansionToolTips))
            set(path, "backgroundColor", Self.describe(color: tableView.backgroundColor))
            set(path, "gridColor", Self.describe(color: tableView.gridColor))
            set(path, "gridStyleMask", String(tableView.gridStyleMask.rawValue))
            set(path, "headerViewIsNil", String(tableView.headerView == nil))
            set(path, "style", String(tableView.style.rawValue))
            set(path, "selectionHighlightStyle", String(tableView.selectionHighlightStyle.rawValue))
            set(path, "usesAlternatingRowBackgroundColors", String(tableView.usesAlternatingRowBackgroundColors))
            set(path, "dataSource", tableView.dataSource.map { Self.className(of: $0) } ?? "nil")
            set(path, "delegate", tableView.delegate.map { Self.className(of: $0) } ?? "nil")
            set(path, "doubleAction", tableView.doubleAction.map { NSStringFromSelector($0) as String } ?? "nil")
            for (j, column) in tableView.tableColumns.enumerated() {
                let columnPath = "\(path)/column[\(j)]"
                set(columnPath, "identifier", column.identifier.rawValue)
                set(columnPath, "title", column.title)
                set(columnPath, "width", String(describing: column.width))
                set(columnPath, "minWidth", String(describing: column.minWidth))
                set(columnPath, "maxWidth", String(describing: column.maxWidth))
                set(columnPath, "resizingMask", String(column.resizingMask.rawValue))
                let headerCell = column.headerCell
                set(columnPath, "headerAlignment", String(headerCell.alignment.rawValue))
                set(columnPath, "headerLineBreakMode", String(headerCell.lineBreakMode.rawValue))
                set(columnPath, "headerTextColor", Self.describe(color: headerCell.textColor))
                set(columnPath, "headerBackgroundColor", Self.describe(color: headerCell.backgroundColor))
                if let dataCell = column.dataCell as? NSCell {
                    set(columnPath, "dataCellClass", Self.className(of: dataCell))
                    if let textCell = dataCell as? NSTextFieldCell {
                        set(columnPath, "dataCellStringValue", textCell.stringValue)
                        set(columnPath, "dataCellIsEditable", String(textCell.isEditable))
                        set(columnPath, "dataCellIsSelectable", String(textCell.isSelectable))
                        set(columnPath, "dataCellAlignment", String(textCell.alignment.rawValue))
                        set(columnPath, "dataCellLineBreakMode", String(textCell.lineBreakMode.rawValue))
                        set(columnPath, "dataCellFont", Self.describe(font: textCell.font))
                        set(columnPath, "dataCellTextColor", Self.describe(color: textCell.textColor))
                        set(columnPath, "dataCellBackgroundColor", Self.describe(color: textCell.backgroundColor))
                    }
                } else {
                    set(columnPath, "dataCellClass", "nil")
                }
            }
            return
        }

        for (index, subview) in view.subviews.enumerated() {
            record(view: subview, path: "\(path)/\(index):\(Self.className(of: subview))")
        }
    }
}
