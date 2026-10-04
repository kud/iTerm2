//
//  SettingsPointerPaneComparisonTests.swift
//  iTerm2
//
//  Proves the code-built Settings > Pointer pane matches the XIB-built one,
//  structurally and in its translations.

import XCTest
@testable import iTerm2SharedARC

final class SettingsPointerPaneComparisonTests: XCTestCase {
    func testCodeBuiltPointerPaneMatchesNib() throws {
        let panel = PreferencePanel.sharedInstance()
        _ = panel.window
        guard let nibController = panel.pointerViewController() else {
            XCTFail("PreferencePanel has no pointer view controller")
            return
        }
        guard !nibController.viewIsBuiltInCode else {
            throw XCTSkip("The pointer pane is built in code in this environment, so there is no nib build to compare against")
        }
        let codeController = PointerPreferencesViewController(nibName: nil, bundle: nil)
        codeController.loadViewInCodeAndDefineControlsForTesting(pointerPrefsController: nibController.pointerPrefsController)

        let nibDump = iTermSettingsViewDump(root: nibController.view)
        nibDump.addBindings(of: nibController)
        let codeDump = iTermSettingsViewDump(root: codeController.view)
        codeDump.addBindings(of: codeController)

        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let nibURL = directory.appendingPathComponent("settings-pointer-nib.json")
        let codeURL = directory.appendingPathComponent("settings-pointer-code.json")
        try nibDump.json.write(to: nibURL, atomically: true, encoding: .utf8)
        try codeDump.json.write(to: codeURL, atomically: true, encoding: .utf8)
        print(nibURL.path)
        print(codeURL.path)

        let differences = iTermSettingsViewDump.differences(expected: nibDump, actual: codeDump)
        Self.unbindRecursively(codeController.view)
        XCTAssertEqual(differences, [], differences.joined(separator: "\n"))
    }

    func testPointerStringsKeepTheirTranslations() throws {
        struct Mapping: Decodable {
            var from: String
            var to: String
            var comment: String
            var english: String
        }
        let thisFile = URL(fileURLWithPath: #filePath)
        let mappingURL = thisFile.deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("tools")
            .appendingPathComponent("xib_strings_maps")
            .appendingPathComponent("pointer.json")
        let mappings = try JSONDecoder().decode([Mapping].self,
                                                from: Data(contentsOf: mappingURL))
        var checked = 0
        for localization in Bundle.main.localizations where localization != "Base" {
            guard let path = Bundle.main.path(forResource: localization, ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                continue
            }
            if localization == "en" {
                // The xib's English lives in Base.lproj, so check the code catalog against the mapping instead.
                for mapping in mappings {
                    let code = bundle.localizedString(forKey: mapping.to,
                                                      value: "<missing>",
                                                      table: "Localizable")
                    XCTAssertEqual(code, mapping.english, "en \(mapping.to)")
                }
                continue
            }
            checked += 1
            for mapping in mappings {
                let xib = bundle.localizedString(forKey: mapping.from,
                                                 value: "<missing>",
                                                 table: "PreferencePanel")
                let code = bundle.localizedString(forKey: mapping.to,
                                                  value: "<missing>",
                                                  table: "Localizable")
                XCTAssertNotEqual(code, "<missing>", "\(localization) \(mapping.to)")
                XCTAssertEqual(xib, code, "\(localization) \(mapping.from)")
            }
        }
        XCTAssertGreaterThan(checked, 0, "No non-English localizations were checked")
    }

    private static func unbindRecursively(_ view: NSView) {
        if view.infoForBinding(.enabled) != nil {
            view.unbind(.enabled)
        }
        for subview in view.subviews {
            unbindRecursively(subview)
        }
        if let tabView = view as? NSTabView {
            for item in tabView.tabViewItems {
                if let itemView = item.view {
                    unbindRecursively(itemView)
                }
            }
        }
        if let scrollView = view as? NSScrollView,
           let documentView = scrollView.documentView {
            unbindRecursively(documentView)
        }
    }
}
