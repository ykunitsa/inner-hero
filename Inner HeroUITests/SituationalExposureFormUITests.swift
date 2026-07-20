//
//  SituationalExposureFormUITests.swift
//  Inner HeroUITests
//
//  Regression test for the situational exposure form: expanding the note
//  must scroll the sheet so the editor is fully visible above the pinned
//  Save button.
//

import XCTest

final class SituationalExposureFormUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddNoteScrollsEditorAboveSaveButton() throws {
        let app = XCUIApplication()
        // The argument domain feeds @AppStorage — skips onboarding.
        app.launchArguments += ["-hasCompletedOnboarding", "YES"]
        app.launch()

        // Today → hero card → form sheet.
        let heroCard = app.buttons
            .matching(NSPredicate(format: "label CONTAINS 'Log an exposure'"))
            .firstMatch
        XCTAssertTrue(heroCard.waitForExistence(timeout: 5), "Hero card not found on Today")
        heroCard.tap()

        let addNote = app.buttons["Add a note"]
        XCTAssertTrue(addNote.waitForExistence(timeout: 5), "Add a note row not found")

        let situationEditor = app.textViews.element(boundBy: 0)
        XCTAssertTrue(situationEditor.waitForExistence(timeout: 2))
        let situationFrameBefore = situationEditor.frame

        addNote.tap()

        // Note editor is the second text view once expanded.
        let noteEditor = app.textViews.element(boundBy: 1)
        XCTAssertTrue(noteEditor.waitForExistence(timeout: 3), "Note editor did not appear")

        // Let the scroll animation settle.
        Thread.sleep(forTimeInterval: 1.0)

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists)

        let noteFrame = noteEditor.frame
        let saveFrame = saveButton.frame
        let situationFrameAfter = situationEditor.frame

        let diagnostics = """
        situation before: \(situationFrameBefore)
        situation after:  \(situationFrameAfter)
        note editor:      \(noteFrame)
        save button:      \(saveFrame)
        """

        XCTAssertLessThan(
            situationFrameAfter.minY, situationFrameBefore.minY,
            "Sheet did not scroll at all.\n\(diagnostics)"
        )
        XCTAssertLessThanOrEqual(
            noteFrame.maxY, saveFrame.minY + 1,
            "Note editor is covered by the Save button.\n\(diagnostics)"
        )
    }
}
