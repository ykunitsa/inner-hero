//
//  DesignSystemTests.swift
//  Inner HeroTests
//
//  Invariants of the design system: typography scale.
//

import Testing
import SwiftUI
@testable import Inner_Hero

@Suite("Typography")
struct TypographyTests {

    @Test("No style is below the 11pt floor")
    func minimumSize() {
        for style in AppTextStyle.allCases {
            #expect(style.size >= 11, "\(style) is smaller than the allowed minimum")
        }
    }

    @Test("Exactly the timer/stat styles are monospaced")
    func monospacedDesign() {
        let monoStyles: [AppTextStyle] = [.mono, .monoLarge, .statValue]
        for style in AppTextStyle.allCases {
            #expect(
                (style.design == .monospaced) == monoStyles.contains(style),
                "\(style) has unexpected design \(style.design)"
            )
        }
    }

    @Test("Caption is the only tracked (kerned) style")
    func kerning() {
        for style in AppTextStyle.allCases {
            #expect((style.kerning > 0) == (style == .caption))
        }
    }

    @Test("Line spacing is never negative")
    func lineSpacing() {
        for style in AppTextStyle.allCases {
            #expect(style.lineSpacing >= 0)
        }
    }
}
