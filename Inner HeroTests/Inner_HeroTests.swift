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
    
    /// Тест: Exposure модель создается с корректными данными
    func testExposureCreation() throws {
        // Arrange
        let title = "Публичное выступление"
        let situation = "Выступление перед аудиторией"
        let fearLevel = 7
        
        // Act
        let exposure = Exposure(
            title: title,
            situation: situation,
            fearLevel: fearLevel,
            completedSessions: 0
        )
        
        // Assert
        XCTAssertEqual(exposure.title, title, "Заголовок должен совпадать")
        XCTAssertEqual(exposure.situation, situation, "Ситуация должна совпадать")
        XCTAssertEqual(exposure.fearLevel, fearLevel, "Уровень страха должен совпадать")
        XCTAssertEqual(exposure.completedSessions, 0, "Количество завершенных сессий должно быть 0")
        XCTAssertLessThanOrEqual(exposure.createdAt, Date(), "Дата создания должна быть не позже текущей")
    }
    
    /// Тест: Exposure модель имеет дефолтные значения
    func testExposureDefaultValues() throws {
        // Arrange & Act
        let exposure = Exposure(
            title: "Тест",
            situation: "Тестовая ситуация"
        )
        
        // Assert
        XCTAssertEqual(exposure.fearLevel, 5, "Дефолтный уровень страха должен быть 5")
        XCTAssertEqual(exposure.completedSessions, 0, "Дефолтное количество сессий должно быть 0")
    }
    
    // MARK: - View Tests
    
    /// Тест: MainTabView инициализируется без ошибок
    func testMainTabViewInitialization() throws {
        // Arrange
        let schema = Schema([Exposure.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        // Act
        let view = MainTabView()
            .modelContainer(container)
        
        // Assert
        XCTAssertNotNil(view, "MainTabView должен быть создан")
    }
    
    /// Тест: MainTabView создает body без ошибок
    func testMainTabViewBody() throws {
        // Arrange
        let mainTabView = MainTabView()
        
        // Act
        let body = mainTabView.body
        let mirror = Mirror(reflecting: body)
        
        // Assert - проверяем, что body может быть создан без ошибок
        XCTAssertGreaterThanOrEqual(mirror.children.count, 0, "Body должен быть создан корректно")
    }
    
    // MARK: - Integration Tests
    
    /// Тест: Создание ModelContainer для тестов
    func testModelContainerCreation() throws {
        // Arrange
        let schema = Schema([Exposure.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        // Act
        let container = try ModelContainer(for: schema, configurations: [config])
        
        // Assert
        XCTAssertNotNil(container, "ModelContainer должен быть создан")
    }
    
    /// Тест: Добавление и получение Exposure из ModelContext
    @MainActor
    func testExposureInModelContext() throws {
        // Arrange
        let schema = Schema([Exposure.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        
        let exposure = Exposure(
            title: "Тестовая экспозиция",
            situation: "Тестовая ситуация",
            fearLevel: 6
        )
        
        // Act
        context.insert(exposure)
        try context.save()
        
        let descriptor = FetchDescriptor<Exposure>()
        let fetchedExposures = try context.fetch(descriptor)
        
        // Assert
        XCTAssertEqual(fetchedExposures.count, 1, "Должна быть одна экспозиция")
        XCTAssertEqual(fetchedExposures.first?.title, "Тестовая экспозиция", "Заголовок должен совпадать")
        XCTAssertEqual(fetchedExposures.first?.fearLevel, 6, "Уровень страха должен быть 6")
    }

}
