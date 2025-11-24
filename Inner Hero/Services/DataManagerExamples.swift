//
//  DataManagerExamples.swift
//  Inner Hero
//
//  Примеры использования DataManager
//
//  ОБНОВЛЕНО: 25 октября 2025
//  - Заменены SUDS на anxiety (anxietyBefore, anxietyAfter)
//  - Удалены промежуточные измерения SUDS (sudsDuring, addSudsDuring)
//  - Добавлено отслеживание выполнения шагов (completedStepIndices)
//  - Добавлено отслеживание времени по шагам (stepTimings)
//  - Добавлены новые методы: markStepCompleted, setStepTime, updateSessionProgress
//

import Foundation
import SwiftData

/*
 MARK: - Инициализация DataManager
 
 В SwiftUI View:
 ```swift
 struct ContentView: View {
     @Environment(\.modelContext) private var modelContext
     
     var body: some View {
         let dataManager = DataManager(modelContext: modelContext)
         // Используйте dataManager
     }
 }
 ```
 
 Или создайте как @State переменную:
 ```swift
 struct ContentView: View {
     @Environment(\.modelContext) private var modelContext
     @State private var dataManager: DataManager?
     
     var body: some View {
         VStack {
             // UI
         }
         .onAppear {
             if dataManager == nil {
                 dataManager = DataManager(modelContext: modelContext)
             }
         }
     }
 }
 ```
*/

// MARK: - Примеры работы с Exposure

func exampleCreateExposure(dataManager: DataManager) {
    do {
        // Создание простой экспозиции
        let exposure1 = try dataManager.createExposure(
            title: "Поход в магазин",
            description: "Сходить в продуктовый магазин в часы пик"
        )
        print("Создана экспозиция: \(exposure1.title)")
        
        // Создание экспозиции с шагами
        let steps = [
            Step(text: "Подготовить презентацию", hasTimer: false, timerDuration: 0, order: 0),
            Step(text: "Отрепетировать речь", hasTimer: true, timerDuration: 300, order: 1),
            Step(text: "Прийти за 10 минут до начала", hasTimer: false, timerDuration: 0, order: 2),
            Step(text: "Сделать 3 глубоких вдоха", hasTimer: true, timerDuration: 60, order: 3),
            Step(text: "Начать выступление", hasTimer: false, timerDuration: 0, order: 4)
        ]
        
        let exposure2 = try dataManager.createExposure(
            title: "Публичное выступление",
            description: "Выступить с презентацией перед коллегами",
            steps: steps
        )
        print("Создана экспозиция с шагами: \(exposure2.title)")
        
    } catch {
        print("Ошибка при создании экспозиции: \(error)")
    }
}

func exampleFetchExposures(dataManager: DataManager) {
    do {
        // Получить все экспозиции
        let allExposures = try dataManager.fetchAllExposures()
        print("Всего экспозиций: \(allExposures.count)")
        
        // Получить экспозиции с сортировкой по дате создания
        let sortedByDate = try dataManager.fetchAllExposures(
            sortBy: [SortDescriptor(\Exposure.createdAt, order: .reverse)]
        )
        print("Последняя созданная экспозиция: \(sortedByDate.first?.title ?? "Нет")")
        
        // Поиск по названию
        let searchTerm = "магазин"
        let searchResults = try dataManager.fetchExposures(
            where: #Predicate { exposure in
                exposure.title.localizedStandardContains(searchTerm)
            }
        )
        print("Найдено по запросу '\(searchTerm)': \(searchResults.count)")
        
    } catch {
        print("Ошибка при получении экспозиций: \(error)")
    }
}

func exampleUpdateExposure(dataManager: DataManager) {
    do {
        // Получить экспозицию
        guard let exposure = try dataManager.fetchAllExposures().first else {
            print("Нет экспозиций для обновления")
            return
        }
        
        // Обновить только название
        try dataManager.updateExposure(exposure, title: "Новое название")
        
        // Обновить несколько полей
        try dataManager.updateExposure(
            exposure,
            title: "Обновленное название",
            description: "Новое описание"
        )
        
        // Добавить/обновить шаги
        let newSteps = [
            Step(text: "Шаг 1: Подготовка", hasTimer: false, timerDuration: 0, order: 0),
            Step(text: "Шаг 2: Выполнение", hasTimer: true, timerDuration: 180, order: 1),
            Step(text: "Шаг 3: Анализ", hasTimer: false, timerDuration: 0, order: 2)
        ]
        try dataManager.updateExposure(
            exposure,
            steps: newSteps
        )
        
        print("Экспозиция обновлена: \(exposure.title)")
        
    } catch {
        print("Ошибка при обновлении экспозиции: \(error)")
    }
}

func exampleDeleteExposure(dataManager: DataManager) {
    do {
        // Создать тестовую экспозицию
        let exposure = try dataManager.createExposure(
            title: "Тестовая экспозиция",
            description: "Для удаления"
        )
        
        let exposureId = exposure.id
        
        // Удалить по объекту
        try dataManager.deleteExposure(exposure)
        print("Экспозиция удалена")
        
        // Или удалить по ID
        // try dataManager.deleteExposure(byId: exposureId)
        
    } catch {
        print("Ошибка при удалении экспозиции: \(error)")
    }
}

// MARK: - Примеры работы с SessionResult

func exampleCreateSession(dataManager: DataManager) {
    do {
        // Получить или создать экспозицию
        guard let exposure = try dataManager.fetchAllExposures().first else {
            print("Сначала создайте экспозицию")
            return
        }
        
        // Создать сеанс
        let session = try dataManager.createSessionResult(
            for: exposure,
            anxietyBefore: 8,
            notes: "Немного волнуюсь перед началом"
        )
        print("Создан сеанс для экспозиции: \(exposure.title)")
        print("Тревога до начала: \(session.anxietyBefore)")
        
    } catch {
        print("Ошибка при создании сеанса: \(error)")
    }
}

func exampleUpdateSession(dataManager: DataManager) {
    do {
        guard let exposure = try dataManager.fetchAllExposures().first else { return }
        
        // Создать сеанс
        let session = try dataManager.createSessionResult(
            for: exposure,
            anxietyBefore: 8
        )
        
        // Отметить шаги как выполненные
        try dataManager.markStepCompleted(session, stepIndex: 0)
        try dataManager.markStepCompleted(session, stepIndex: 1)
        try dataManager.markStepCompleted(session, stepIndex: 2)
        
        // Сохранить время для каждого шага
        try dataManager.setStepTime(session, stepIndex: 0, time: 30.0)  // 30 секунд
        try dataManager.setStepTime(session, stepIndex: 1, time: 45.5)  // 45.5 секунд
        try dataManager.setStepTime(session, stepIndex: 2, time: 60.0)  // 1 минута
        
        print("Выполнено шагов: \(session.completedStepIndices.count)")
        print("Общее время шагов: \(session.getTotalStepsTime()) секунд")
        
        // Завершить сеанс
        try dataManager.completeSession(
            session,
            anxietyAfter: 4,
            notes: "Чувствую себя намного лучше! Справился с задачей."
        )
        
        print("Сеанс завершен. Тревога после: \(session.anxietyAfter ?? 0)")
        
    } catch {
        print("Ошибка при обновлении сеанса: \(error)")
    }
}

func exampleFetchSessions(dataManager: DataManager) {
    do {
        // Получить все сеансы
        let allSessions = try dataManager.fetchAllSessionResults()
        print("Всего сеансов: \(allSessions.count)")
        
        // Получить сеансы с сортировкой
        let recentSessions = try dataManager.fetchAllSessionResults(
            sortBy: [SortDescriptor(\SessionResult.startAt, order: .reverse)]
        )
        print("Последний сеанс: \(recentSessions.first?.startAt ?? Date())")
        
        // Получить завершенные сеансы
        let completedSessions = try dataManager.fetchSessionResults(
            where: #Predicate { session in
                session.endAt != nil
            },
            sortBy: [SortDescriptor(\SessionResult.startAt, order: .reverse)]
        )
        print("Завершенных сеансов: \(completedSessions.count)")
        
        // Получить сеансы для конкретной экспозиции
        if let exposure = try dataManager.fetchAllExposures().first {
            let exposureSessions = try dataManager.fetchSessionResults(for: exposure)
            print("Сеансов для '\(exposure.title)': \(exposureSessions.count)")
        }
        
        // Получить сеансы за последнюю неделю
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentSessionsWeek = try dataManager.fetchSessionResults(
            where: #Predicate { session in
                session.startAt >= weekAgo
            }
        )
        print("Сеансов за последнюю неделю: \(recentSessionsWeek.count)")
        
    } catch {
        print("Ошибка при получении сеансов: \(error)")
    }
}

func exampleDeleteSession(dataManager: DataManager) {
    do {
        guard let exposure = try dataManager.fetchAllExposures().first else { return }
        
        // Создать тестовый сеанс
        let session = try dataManager.createSessionResult(
            for: exposure,
            anxietyBefore: 5
        )
        
        let sessionId = session.id
        
        // Удалить по объекту
        try dataManager.deleteSessionResult(session)
        print("Сеанс удален")
        
        // Или удалить по ID
        // try dataManager.deleteSessionResult(byId: sessionId)
        
    } catch {
        print("Ошибка при удалении сеанса: \(error)")
    }
}

// MARK: - Примеры работы с отслеживанием шагов

func exampleStepTracking(dataManager: DataManager) {
    do {
        // Создать экспозицию с шагами
        let steps = [
            Step(text: "Подойти к окну", hasTimer: false, timerDuration: 0, order: 0),
            Step(text: "Смотреть вниз 2 минуты", hasTimer: true, timerDuration: 120, order: 1),
            Step(text: "Сделать глубокий вдох", hasTimer: true, timerDuration: 30, order: 2),
            Step(text: "Отойти от окна", hasTimer: false, timerDuration: 0, order: 3)
        ]
        
        let exposure = try dataManager.createExposure(
            title: "Преодоление страха высоты",
            description: "Постепенное приближение к окну на высоком этаже",
            steps: steps
        )
        
        // Создать сеанс
        let session = try dataManager.createSessionResult(
            for: exposure,
            anxietyBefore: 8
        )
        
        print("=== Отслеживание выполнения шагов ===\n")
        
        // Выполнить первый шаг
        print("Шаг 1: Подойти к окну")
        try dataManager.markStepCompleted(session, stepIndex: 0)
        try dataManager.setStepTime(session, stepIndex: 0, time: 20.0)
        print("✓ Выполнен за 20 сек\n")
        
        // Выполнить второй шаг (с таймером)
        print("Шаг 2: Смотреть вниз 2 минуты (с таймером)")
        try dataManager.markStepCompleted(session, stepIndex: 1)
        try dataManager.setStepTime(session, stepIndex: 1, time: 125.0)  // Немного дольше таймера
        print("✓ Выполнен за 2:05 мин\n")
        
        // Проверить прогресс
        print("Текущий прогресс:")
        print("- Выполнено шагов: \(session.completedStepIndices.count)/\(exposure.steps.count)")
        print("- Общее время: \(Int(session.getTotalStepsTime())) сек")
        
        // Проверить, какие шаги выполнены
        for (index, step) in exposure.steps.enumerated() {
            let completed = session.isStepCompleted(index)
            let time = session.getStepTime(index)
            let status = completed ? "✓" : "○"
            print("\(status) Шаг \(index + 1): \(step.text) (\(Int(time)) сек)")
        }
        
        // Снять отметку с шага (если нужно переделать)
        print("\nПеределать шаг 1...")
        try dataManager.markStepIncomplete(session, stepIndex: 0)
        print("✓ Отметка снята")
        
        // Отметить снова с новым временем
        try dataManager.markStepCompleted(session, stepIndex: 0)
        try dataManager.setStepTime(session, stepIndex: 0, time: 15.0)
        print("✓ Выполнен повторно за 15 сек\n")
        
        // Завершить оставшиеся шаги
        try dataManager.markStepCompleted(session, stepIndex: 2)
        try dataManager.setStepTime(session, stepIndex: 2, time: 30.0)
        
        try dataManager.markStepCompleted(session, stepIndex: 3)
        try dataManager.setStepTime(session, stepIndex: 3, time: 10.0)
        
        // Итоговая статистика
        print("=== Итоговая статистика сеанса ===")
        print("✓ Выполнено: \(session.completedStepIndices.count)/\(exposure.steps.count) шагов")
        print("✓ Общее время: \(Int(session.getTotalStepsTime())) сек")
        print("✓ Среднее время на шаг: \(Int(session.getTotalStepsTime()) / session.completedStepIndices.count) сек")
        
        // Завершить сеанс
        try dataManager.completeSession(session, anxietyAfter: 4)
        
    } catch {
        print("Ошибка: \(error)")
    }
}

func exampleBatchStepUpdate(dataManager: DataManager) {
    do {
        guard let exposure = try dataManager.fetchAllExposures().first else {
            print("Создайте экспозицию сначала")
            return
        }
        
        let session = try dataManager.createSessionResult(
            for: exposure,
            anxietyBefore: 6
        )
        
        // Массовое обновление прогресса
        let completedSteps = [0, 1, 2]
        let stepTimings: [Int: TimeInterval] = [
            0: 25.0,
            1: 40.0,
            2: 55.0
        ]
        
        try dataManager.updateSessionProgress(
            session,
            completedSteps: completedSteps,
            stepTimings: stepTimings
        )
        
        print("=== Массовое обновление прогресса ===")
        print("✓ Обновлено \(completedSteps.count) шагов")
        print("✓ Общее время: \(Int(session.getTotalStepsTime())) сек")
        
    } catch {
        print("Ошибка: \(error)")
    }
}

// MARK: - Статистика и аналитика

func exampleGetStatistics(dataManager: DataManager) {
    do {
        guard let exposure = try dataManager.fetchAllExposures().first else { return }
        
        let stats = try dataManager.getExposureStatistics(exposure)
        
        print("=== Статистика для '\(exposure.title)' ===")
        print("Всего сеансов: \(stats["totalSessions"] ?? 0)")
        print("Завершено сеансов: \(stats["completedSessions"] ?? 0)")
        
        if let avgAnxiety = stats["averageAnxietyAfter"] as? Double {
            print("Средняя тревога после: \(String(format: "%.1f", avgAnxiety))")
        }
        
        if let minAnxiety = stats["minAnxietyAfter"] as? Int {
            print("Минимальная тревога после: \(minAnxiety)")
        }
        
        if let maxAnxiety = stats["maxAnxietyAfter"] as? Int {
            print("Максимальная тревога после: \(maxAnxiety)")
        }
        
        if let avgDuration = stats["averageDurationSeconds"] as? TimeInterval {
            let minutes = Int(avgDuration / 60)
            print("Средняя продолжительность: \(minutes) мин")
        }
        
    } catch {
        print("Ошибка при получении статистики: \(error)")
    }
}

// MARK: - Комплексный пример

func exampleCompleteWorkflow(dataManager: DataManager) {
    do {
        print("=== Полный рабочий процесс ===\n")
        
        // 1. Создать экспозицию с шагами
        print("1. Создание экспозиции...")
        let steps = [
            Step(text: "Найти номер телефона ресторана", hasTimer: false, timerDuration: 0, order: 0),
            Step(text: "Написать что сказать", hasTimer: true, timerDuration: 120, order: 1),
            Step(text: "Сделать 3 глубоких вдоха", hasTimer: true, timerDuration: 60, order: 2),
            Step(text: "Набрать номер", hasTimer: false, timerDuration: 0, order: 3),
            Step(text: "Поздороваться и озвучить просьбу", hasTimer: true, timerDuration: 180, order: 4)
        ]
        
        let exposure = try dataManager.createExposure(
            title: "Звонок незнакомому человеку",
            description: "Позвонить в ресторан и забронировать столик",
            steps: steps
        )
        print("✓ Создана: '\(exposure.title)' с \(exposure.steps.count) шагами\n")
        
        // 2. Начать первый сеанс
        print("2. Начало сеанса...")
        let session1 = try dataManager.createSessionResult(
            for: exposure,
            anxietyBefore: 7,
            notes: "Очень волнуюсь"
        )
        print("✓ Сеанс начат, тревога до: \(session1.anxietyBefore)\n")
        
        // 3. Выполнить шаги и отметить их
        print("3. Выполнение шагов...")
        
        // Шаг 0: без таймера
        try dataManager.markStepCompleted(session1, stepIndex: 0)
        try dataManager.setStepTime(session1, stepIndex: 0, time: 25.0)
        print("✓ Шаг 1 выполнен за 25 сек")
        
        // Шаг 1: с таймером 2 минуты
        try dataManager.markStepCompleted(session1, stepIndex: 1)
        try dataManager.setStepTime(session1, stepIndex: 1, time: 120.0)
        print("✓ Шаг 2 выполнен за 2 мин")
        
        // Шаг 2: с таймером 1 минута
        try dataManager.markStepCompleted(session1, stepIndex: 2)
        try dataManager.setStepTime(session1, stepIndex: 2, time: 60.0)
        print("✓ Шаг 3 выполнен за 1 мин")
        
        // Шаг 3: без таймера
        try dataManager.markStepCompleted(session1, stepIndex: 3)
        try dataManager.setStepTime(session1, stepIndex: 3, time: 15.0)
        print("✓ Шаг 4 выполнен за 15 сек")
        
        // Шаг 4: с таймером 3 минуты
        try dataManager.markStepCompleted(session1, stepIndex: 4)
        try dataManager.setStepTime(session1, stepIndex: 4, time: 180.0)
        print("✓ Шаг 5 выполнен за 3 мин")
        
        print("✓ Всего выполнено: \(session1.completedStepIndices.count)/\(exposure.steps.count) шагов")
        print("✓ Общее время шагов: \(Int(session1.getTotalStepsTime())) сек\n")
        
        // 4. Завершить сеанс
        print("4. Завершение сеанса...")
        try dataManager.completeSession(
            session1,
            anxietyAfter: 4,
            notes: "Справился! Оказалось не так страшно."
        )
        print("✓ Сеанс завершен, тревога после: \(session1.anxietyAfter ?? 0)\n")
        
        // 5. Провести еще несколько сеансов
        print("5. Проведение дополнительных сеансов...")
        
        let session2 = try dataManager.createSessionResult(for: exposure, anxietyBefore: 6)
        // Отметить некоторые шаги
        try dataManager.markStepCompleted(session2, stepIndex: 0)
        try dataManager.markStepCompleted(session2, stepIndex: 1)
        try dataManager.markStepCompleted(session2, stepIndex: 2)
        try dataManager.completeSession(session2, anxietyAfter: 3)
        
        let session3 = try dataManager.createSessionResult(for: exposure, anxietyBefore: 5)
        // Отметить все шаги
        for i in 0..<exposure.steps.count {
            try dataManager.markStepCompleted(session3, stepIndex: i)
        }
        try dataManager.completeSession(session3, anxietyAfter: 2)
        
        print("✓ Проведено еще 2 сеанса\n")
        
        // 6. Получить статистику
        print("6. Анализ прогресса...")
        let stats = try dataManager.getExposureStatistics(exposure)
        print("✓ Всего сеансов: \(stats["totalSessions"] ?? 0)")
        
        if let avgAnxiety = stats["averageAnxietyAfter"] as? Double {
            print("✓ Средняя тревога после сеансов: \(String(format: "%.1f", avgAnxiety))")
        }
        
        if let minAnxiety = stats["minAnxietyAfter"] as? Int {
            print("✓ Лучший результат (минимальная тревога): \(minAnxiety)")
        }
        
        print("\n=== Рабочий процесс завершен успешно! ===")
        
    } catch {
        print("Ошибка в рабочем процессе: \(error)")
    }
}

// MARK: - Использование в SwiftUI View

/*
struct ExampleView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataManager: DataManager?
    @State private var exposures: [Exposure] = []
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(exposures) { exposure in
                    VStack(alignment: .leading) {
                        Text(exposure.title)
                            .font(.headline)
                    }
                }
                .onDelete(perform: deleteExposures)
            }
            .navigationTitle("Экспозиции")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        addExposure()
                    }
                }
            }
            .onAppear {
                setupDataManager()
                loadExposures()
            }
            .alert("Ошибка", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func setupDataManager() {
        if dataManager == nil {
            dataManager = DataManager(modelContext: modelContext)
        }
    }
    
    private func loadExposures() {
        guard let dataManager = dataManager else { return }
        
        do {
            exposures = try dataManager.fetchAllExposures(
                sortBy: [SortDescriptor(\Exposure.createdAt, order: .reverse)]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func addExposure() {
        guard let dataManager = dataManager else { return }
        
        do {
            let _ = try dataManager.createExposure(
                title: "Новая экспозиция",
                description: "Описание"
            )
            loadExposures()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func deleteExposures(at offsets: IndexSet) {
        guard let dataManager = dataManager else { return }
        
        do {
            let exposuresToDelete = offsets.map { exposures[$0] }
            try dataManager.deleteExposures(exposuresToDelete)
            loadExposures()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
*/

