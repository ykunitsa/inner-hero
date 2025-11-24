# DataManager - Сервисный слой для работы с SwiftData

## Описание

`DataManager` - это сервисный слой, который предоставляет удобный API для работы с моделями SwiftData (`Exposure` и `SessionResult`). Класс инкапсулирует логику работы с `ModelContext` и предоставляет CRUD операции, фильтрацию, сортировку и аналитические функции.

## Основные возможности

- ✅ CRUD операции для экспозиций (Exposure)
- ✅ CRUD операции для результатов сеансов (SessionResult)
- ✅ Гибкая фильтрация и сортировка данных
- ✅ Статистика и аналитика по экспозициям
- ✅ Обработка ошибок
- ✅ Batch операции (массовое удаление)

## Инициализация

### В SwiftUI View

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        let dataManager = DataManager(modelContext: modelContext)
        // Используйте dataManager
    }
}
```

### Как @State переменная

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

## API Reference

### Exposure Operations

#### Создание

```swift
// Простая экспозиция
let exposure = try dataManager.createExposure(
    title: "Поход в магазин",
    description: "Сходить в продуктовый магазин в часы пик",
    expectedSUDS: 7,
    difficulty: 5
)

// С шагами
let exposure = try dataManager.createExposure(
    title: "Публичное выступление",
    description: "Выступить с презентацией",
    expectedSUDS: 9,
    difficulty: 8,
    steps: ["Подготовить презентацию", "Отрепетировать", "Выступить"]
)
```

#### Получение

```swift
// Все экспозиции
let all = try dataManager.fetchAllExposures()

// С сортировкой
let sorted = try dataManager.fetchAllExposures(
    sortBy: [SortDescriptor(\Exposure.createdAt, order: .reverse)]
)

// С фильтрацией
let hard = try dataManager.fetchExposures(
    where: #Predicate { $0.difficulty >= 7 }
)

// Поиск по названию
let results = try dataManager.fetchExposures(
    where: #Predicate { $0.title.localizedStandardContains("магазин") }
)

// По ID
let exposure = try dataManager.fetchExposure(byId: id)
```

#### Обновление

```swift
// Одно поле
try dataManager.updateExposure(exposure, title: "Новое название")

// Несколько полей
try dataManager.updateExposure(
    exposure,
    title: "Новое название",
    description: "Новое описание",
    difficulty: 6,
    steps: ["Шаг 1", "Шаг 2"]
)
```

#### Удаление

```swift
// Один объект
try dataManager.deleteExposure(exposure)

// По ID
try dataManager.deleteExposure(byId: id)

// Несколько объектов
try dataManager.deleteExposures([exposure1, exposure2])
```

### SessionResult Operations

#### Создание и управление сеансом

```swift
// Создать сеанс
let session = try dataManager.createSessionResult(
    for: exposure,
    sudsBefore: 8,
    notes: "Немного волнуюсь"
)

// Добавлять значения SUDS во время сеанса
try dataManager.addSudsDuring(to: session, sudsValue: 9)
try dataManager.addSudsDuring(to: session, sudsValue: 7)
try dataManager.addSudsDuring(to: session, sudsValue: 6)

// Завершить сеанс
try dataManager.completeSession(
    session,
    sudsAfter: 4,
    notes: "Справился!"
)
```

#### Получение

```swift
// Все сеансы
let all = try dataManager.fetchAllSessionResults()

// Сеансы конкретной экспозиции
let sessions = try dataManager.fetchSessionResults(for: exposure)

// Завершенные сеансы
let completed = try dataManager.fetchSessionResults(
    where: #Predicate { $0.endAt != nil }
)

// Сеансы за последнюю неделю
let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
let recent = try dataManager.fetchSessionResults(
    where: #Predicate { $0.startAt >= weekAgo }
)
```

#### Обновление

```swift
// Обновить поля
try dataManager.updateSessionResult(
    session,
    endAt: Date(),
    sudsAfter: 5,
    notes: "Дополнительные заметки"
)
```

#### Удаление

```swift
// Один объект
try dataManager.deleteSessionResult(session)

// По ID
try dataManager.deleteSessionResult(byId: id)

// Несколько объектов
try dataManager.deleteSessionResults([session1, session2])
```

### Статистика

```swift
let stats = try dataManager.getExposureStatistics(exposure)

print("Всего сеансов: \(stats["totalSessions"] ?? 0)")
print("Завершено: \(stats["completedSessions"] ?? 0)")

if let avgSuds = stats["averageSudsAfter"] as? Double {
    print("Средний SUDS после: \(avgSuds)")
}

if let avgDuration = stats["averageDurationSeconds"] as? TimeInterval {
    print("Средняя продолжительность: \(avgDuration / 60) мин")
}
```

Возвращаемые поля статистики:
- `totalSessions`: Int - Всего сеансов
- `completedSessions`: Int - Завершенных сеансов
- `averageSudsAfter`: Double - Средний SUDS после
- `minSudsAfter`: Int - Минимальный SUDS после
- `maxSudsAfter`: Int - Максимальный SUDS после
- `averageDurationSeconds`: TimeInterval - Средняя продолжительность в секундах

## Примеры использования

### Полный рабочий процесс

```swift
// 1. Создать экспозицию
let exposure = try dataManager.createExposure(
    title: "Звонок незнакомому человеку",
    description: "Позвонить в ресторан и забронировать столик",
    expectedSUDS: 7,
    difficulty: 6,
    steps: ["Найти номер", "Написать что сказать", "Позвонить"]
)

// 2. Начать сеанс
let session = try dataManager.createSessionResult(
    for: exposure,
    sudsBefore: 7
)

// 3. Добавлять измерения во время выполнения
try dataManager.addSudsDuring(to: session, sudsValue: 8)
try dataManager.addSudsDuring(to: session, sudsValue: 6)
try dataManager.addSudsDuring(to: session, sudsValue: 5)

// 4. Завершить сеанс
try dataManager.completeSession(session, sudsAfter: 4)

// 5. Посмотреть статистику
let stats = try dataManager.getExposureStatistics(exposure)
```

### Использование в SwiftUI

```swift
struct ExposuresListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataManager: DataManager?
    @State private var exposures: [Exposure] = []
    
    var body: some View {
        List(exposures) { exposure in
            Text(exposure.title)
        }
        .onAppear {
            setupDataManager()
            loadExposures()
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
            print("Error loading: \(error)")
        }
    }
}
```

## Обработка ошибок

```swift
do {
    let exposure = try dataManager.createExposure(...)
} catch DataManagerError.saveFailed(let error) {
    print("Не удалось сохранить: \(error)")
} catch DataManagerError.fetchFailed(let error) {
    print("Не удалось загрузить: \(error)")
} catch DataManagerError.notFound {
    print("Данные не найдены")
} catch {
    print("Неизвестная ошибка: \(error)")
}
```

## Типы ошибок

- `DataManagerError.saveFailed(Error)` - Ошибка при сохранении данных
- `DataManagerError.fetchFailed(Error)` - Ошибка при загрузке данных
- `DataManagerError.notFound` - Данные не найдены

## Best Practices

1. **Инициализация**: Создавайте один экземпляр DataManager на View и переиспользуйте его
2. **Обработка ошибок**: Всегда оборачивайте вызовы в try-catch
3. **Сортировка**: Используйте SortDescriptor для упорядочивания данных
4. **Фильтрация**: Используйте #Predicate макрос для типобезопасной фильтрации
5. **UI обновление**: После изменения данных обновляйте UI
6. **Производительность**: Для больших списков используйте фильтрацию и пагинацию

## Дополнительная документация

Подробные примеры использования смотрите в файле `DataManagerExamples.swift`.

## Лицензия

Inner Hero © 2025

