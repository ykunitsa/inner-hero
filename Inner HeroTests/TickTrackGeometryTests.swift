import Testing
import CoreGraphics
@testable import Inner_Hero

/// The shared geometry behind `ScaleChoice`, `IntensitySlider` and
/// `DurationRangeSlider`. Pure math, so it is worth pinning down here rather
/// than by poking at a simulator.
@Suite("Tick track geometry")
struct TickTrackGeometryTests {

    private let width: CGFloat = 343

    @Test("Ends sit inside the track, not on its edge")
    func endsAreInset() {
        let geometry = TickTrackGeometry(bounds: 0...3, inset: 4)

        #expect(geometry.position(of: 0, width: width) == 4)
        #expect(geometry.position(of: 3, width: width) == width - 4)
    }

    @Test("Stops are evenly spaced")
    func stopsAreEvenlySpaced() {
        let geometry = TickTrackGeometry(bounds: 0...3, inset: 4)
        let positions = (0...3).map { geometry.position(of: $0, width: width) }
        let gaps = zip(positions, positions.dropFirst()).map { $1 - $0 }

        for gap in gaps.dropFirst() {
            #expect(abs(gap - gaps[0]) < 0.001)
        }
    }

    @Test("A touch resolves to the nearest stop")
    func touchPicksNearestStop() {
        let geometry = TickTrackGeometry(bounds: 0...3, inset: 4)

        for stop in 0...3 {
            let x = geometry.position(of: stop, width: width)
            #expect(geometry.value(atX: x, width: width) == stop)
            // Just short of halfway to the neighbour still belongs to `stop`.
            #expect(geometry.value(atX: x + 40, width: width) == stop)
        }
    }

    @Test("Touches beyond the ends clamp instead of overflowing")
    func touchesClamp() {
        let geometry = TickTrackGeometry(bounds: 0...3, inset: 4)

        #expect(geometry.value(atX: -500, width: width) == 0)
        #expect(geometry.value(atX: width + 500, width: width) == 3)
    }

    @Test("A single-stop track does not divide by zero")
    func degenerateBounds() {
        let geometry = TickTrackGeometry(bounds: 0...0, inset: 4)

        #expect(geometry.position(of: 0, width: width) == 4)
        #expect(geometry.value(atX: 200, width: width) == 0)
    }

    @Test("Default inset falls back to half a tick")
    func defaultInset() {
        let geometry = TickTrackGeometry(bounds: 1...20)

        #expect(geometry.position(of: 1, width: width) == 0.75)
        #expect(geometry.value(atX: 0, width: width) == 1)
        #expect(geometry.value(atX: width, width: width) == 20)
    }
}
