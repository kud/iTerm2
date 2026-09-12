//
//  PTYSessionCollapsedArrangementTests.swift
//  iTerm2 ModernTests
//
//  A collapsed pane's SessionView state (collapsed / expandedFraction) is
//  persisted through the session arrangement dictionary so it survives
//  save/restore. These tests pin the encode half of that contract:
//  encodeArrangementWithContents:encoder: must write "Collapsed" /
//  "Collapsed Expanded Fraction" when the view is collapsed, and must omit
//  both keys otherwise so a plain session's arrangement doesn't grow -
//  matching how every other off-by-default flag on this path is encoded
//  (see autoSendClippingsWhenIdle a few lines above it in PTYSession.m).
//

import XCTest
@testable import iTerm2SharedARC

final class PTYSessionCollapsedArrangementTests: XCTestCase {
    func testCollapsedSessionEncodesCollapsedStateAndFraction() {
        let session = PTYSession(synthetic: false)!
        let view = SessionView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        view.expandedFraction = 0.42
        view.collapsed = true
        session.view = view

        let encoder = iTermMutableDictionaryEncoderAdapter.encoder()
        session.encodeArrangement(withContents: false, encoder: encoder)
        let dict = encoder.mutableDictionary as? [AnyHashable: Any] ?? [:]

        XCTAssertEqual(dict["Collapsed"] as? Bool, true)
        XCTAssertEqual((dict["Collapsed Expanded Fraction"] as? NSNumber)?.doubleValue ?? -1, 0.42,
                       accuracy: 0.0001)
    }

    func testUncollapsedSessionOmitsCollapsedKeys() {
        let session = PTYSession(synthetic: false)!
        session.view = SessionView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))

        let encoder = iTermMutableDictionaryEncoderAdapter.encoder()
        session.encodeArrangement(withContents: false, encoder: encoder)
        let dict = encoder.mutableDictionary as? [AnyHashable: Any] ?? [:]

        XCTAssertNil(dict["Collapsed"], "A plain session's arrangement must not grow the Collapsed key")
        XCTAssertNil(dict["Collapsed Expanded Fraction"])
    }
}
