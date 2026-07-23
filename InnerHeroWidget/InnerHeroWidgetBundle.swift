import SwiftUI
import WidgetKit

/// The four widgets of §11.7.
///
/// Spec §9 says "один виджет". Four is a ratified amendment (author's decision,
/// July 2026, `docs/plans/11.7-widget.md`): §9's hard priority is not weakened, it
/// moves wholesale into `TodayWidget`, and the other three exist because §3
/// separately describes an exposure button — an entry with a shelf life that the
/// priority widget hides for days whenever a BA tail is open.
///
/// Behavioral activation gets no tile of its own: its door is the "how much energy"
/// question, so a BA button would lead to a question rather than an action (§1.2).
/// What BA actually puts on a home screen is its tail, and that lives in
/// `TodayWidget`.
@main
struct InnerHeroWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        LogExposureWidget()
        BreathingWidget()
        RelaxationWidget()
    }
}
