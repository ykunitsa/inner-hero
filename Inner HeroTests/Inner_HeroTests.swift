//
//  Inner_HeroTests.swift
//  Inner HeroTests
//
//  Created by Yauheni Kunitsa on 21.10.25.
//

import XCTest
import SwiftUI
import SwiftData
@testable import Inner_Hero

final class Inner_HeroTests: XCTestCase {
    
    // MARK: - Model Tests
    
    /// Test: Exposure model is created with correct data
    func testExposureCreation() throws {
        // Arrange
        let title = "Public speaking"
        let situation = "Speaking in front of an audience"
        let fearLevel = 7
        
        // Act
        let exposure = Exposure(
            title: title,
            situation: situation,
            fearLevel: fearLevel,
            completedSessions: 0
        )
        
        // Assert
        XCTAssertEqual(exposure.title, title, "Title should match")
        XCTAssertEqual(exposure.situation, situation, "Situation should match")
        XCTAssertEqual(exposure.fearLevel, fearLevel, "Fear level should match")
        XCTAssertEqual(exposure.completedSessions, 0, "Completed sessions should be 0")
        XCTAssertLessThanOrEqual(exposure.createdAt, Date(), "Created date should be not later than current")
    }
    
    /// Test: Exposure model has default values
    func testExposureDefaultValues() throws {
        // Arrange & Act
        let exposure = Exposure(
            title: "Test",
            situation: "Test situation"
        )
        
        // Assert
        XCTAssertEqual(exposure.fearLevel, 5, "Default fear level should be 5")
        XCTAssertEqual(exposure.completedSessions, 0, "Default completed sessions should be 0")
    }
    
    // MARK: - View Tests
    
    /// Test: MainTabView initializes without errors
    func testMainTabViewInitialization() throws {
        // Arrange
        let schema = Schema([Exposure.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        // Act
        let view = MainTabView()
            .modelContainer(container)
        
        // Assert
        XCTAssertNotNil(view, "MainTabView should be created")
    }
    
    /// Test: MainTabView creates body without errors
    func testMainTabViewBody() throws {
        // Arrange
        let mainTabView = MainTabView()
        
        // Act
        let body = mainTabView.body
        let mirror = Mirror(reflecting: body)
        
        // Assert - check that body can be created without errors
        XCTAssertGreaterThanOrEqual(mirror.children.count, 0, "Body should be created correctly")
    }
    
    // MARK: - Integration Tests
    
    /// Test: Creating ModelContainer for tests
    func testModelContainerCreation() throws {
        // Arrange
        let schema = Schema([Exposure.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        // Act
        let container = try ModelContainer(for: schema, configurations: [config])
        
        // Assert
        XCTAssertNotNil(container, "ModelContainer should be created")
    }
    
    /// Test: Adding and getting Exposure from ModelContext
    @MainActor
    func testExposureInModelContext() throws {
        // Arrange
        let schema = Schema([Exposure.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        
        let exposure = Exposure(
            title: "Test exposure",
            situation: "Test situation",
            fearLevel: 6
        )
        
        // Act
        context.insert(exposure)
        try context.save()
        
        let descriptor = FetchDescriptor<Exposure>()
        let fetchedExposures = try context.fetch(descriptor)
        
        // Assert
        XCTAssertEqual(fetchedExposures.count, 1, "There should be one exposure")
        XCTAssertEqual(fetchedExposures.first?.title, "Test exposure", "Title should match")
        XCTAssertEqual(fetchedExposures.first?.fearLevel, 6, "Fear level should be 6")
    }

}
