//
//  DesignSystemTests.swift
//  Inner HeroTests
//
//  Invariants of the design system: typography scale and the
//  IntensitySlider position→value mapping.
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

@Suite("IntensitySlider position→value mapping")
struct IntensitySliderTests {

    private let range = 0...10
    private let thumb: CGFloat = 32
    private let width: CGFloat = 300 // usable track width (minus thumb)

    private func value(at x: CGFloat) -> Int {
        IntensitySlider.value(atX: x, usableWidth: width, thumbSize: thumb, range: range)
    }

    @Test("Left edge and overshoot clamp to the lower bound")
    func leftEdge() {
        #expect(value(at: 0) == 0)
        #expect(value(at: -50) == 0)
        #expect(value(at: thumb / 2) == 0)
    }

    @Test("Right edge and overshoot clamp to the upper bound")
    func rightEdge() {
        #expect(value(at: thumb / 2 + width) == 10)
        #expect(value(at: 10_000) == 10)
    }

    @Test("Track center maps to the middle of the scale")
    func center() {
        #expect(value(at: thumb / 2 + width / 2) == 5)
    }

    @Test("Positions snap to the nearest step")
    func snapping() {
        let stepWidth = width / 10
        #expect(value(at: thumb / 2 + stepWidth * 3.4) == 3)
        #expect(value(at: thumb / 2 + stepWidth * 3.6) == 4)
    }

    @Test("Degenerate single-value range always returns its only value")
    func singleValueRange() {
        for x: CGFloat in [-10, 0, 150, 10_000] {
            #expect(IntensitySlider.value(atX: x, usableWidth: width, thumbSize: thumb, range: 5...5) == 5)
        }
    }

    @Test("Non-zero lower bound offsets the result")
    func customRange() {
        #expect(IntensitySlider.value(atX: 0, usableWidth: width, thumbSize: thumb, range: 1...5) == 1)
        #expect(IntensitySlider.value(atX: thumb / 2 + width, usableWidth: width, thumbSize: thumb, range: 1...5) == 5)
    }

    @Test("Zero usable width does not crash and stays in range")
    func zeroWidth() {
        let result = IntensitySlider.value(atX: 100, usableWidth: 0, thumbSize: thumb, range: range)
        #expect(range.contains(result))
    }
}
