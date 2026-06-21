# Inner Hero — Tech Debt & «Осторожно здесь»

Известные слабые места по состоянию на 2026-06-21. Не опираться на перечисленное как
на образец. При работе рядом — по возможности улучшать, но не «по пути» ломать.
Закрытые пункты — удалять из файла.

Приоритеты: 🔴 критично · 🟠 важно · 🟡 желательно.

---

## 🔴 Критично

### 1. Тестов практически нет (<1% покрытия)
6 тестов моделей + пустые UI-шаблоны из коробки. Не покрыты ключевые места:
`Services/SessionCompletionService`, `Features/Schedule/ViewModels/ScheduleViewModel`,
миграции `App/Schema/AppMigrationPlan`.
→ В первую очередь покрыть `SessionCompletionService` (идемпотентность) и миграцию V1→V2.

### 2. Миграция V1→V2 безвозвратно удаляет данные
`App/Schema/AppMigrationPlan.swift` удаляет BA-assignments, completions и legacy-модели
без архивации. Нет транзакционной гарантии между `willMigrate`/`didMigrate`; seed данных
в `didMigrate` без проверки на дубли. Тестов нет.
→ Сохранять архив перед удалением; добавить дедуп-проверку перед insert; покрыть тестом.

### 3. `fatalError` в release-сборке
`App/Inner_HeroApp.swift:56` — при отказе in-memory фолбэка приложение крашится в проде.
Плюс вложенный `#if DEBUG` внутри `#else` (логическая ошибка условной компиляции, ~стр. 32–56).
→ Заменить на graceful degradation + диагностику; убрать вложенный `#if`.

### 4. Слабые связи в модели данных (риск осиротевших записей)
`ActivationSession.activityId: UUID` и `ActivationTask.categoryId: UUID` — «ручные FK»
вместо `@Relationship`. Нет каскадного удаления → при удалении задачи остаются
висячие сессии. В `ExerciseAssignment` смешаны типы: часть полей `UUID?`, часть — `String?`
(rawValue енама).
→ Перевести на `@Relationship` с `deleteRule: .cascade`; унифицировать типы (требует миграции).

---

## 🟠 Важно

### 5. Утечка таймера / Task без отмены
Session-flow: `Timer.publish().autoconnect()` в `@State` без отмены в `onDisappear`.
Анимация «рулетки» в `Features/BehavioralActivation/Views/BehavioralActivationRootView.swift`
(~стр. 523–568) запускает `Task` без cancellation и делает `randomElement()!` / `delays.last!`
(потенциальный краш + обновление UI закрытой вьюхи).
→ Отменять Timer/Task в `onDisappear`; заменить force-unwrap на `?? fallback`.

### 6. Молчаливое проглатывание ошибок
~36 `try?` с `?? 0`/fallback, особенно в `ScheduleViewModel` (по 5–7 подряд) — при сбое БД
пользователь видит неверные цифры вместо лога/краша. ~21 `print()` вместо `Logger`
(не попадают в Console.app, нет уровней).
→ Завести `Logger` (os.log) с уровнями; не глушить ошибки БД без логирования.

### 7. «Массивные вьюхи»
Крупнейшие файлы (строк): `Core/DesignSystem/Components.swift` (1265),
`Features/BehavioralActivation/Views/BehavioralActivationRootView.swift` (920),
`Features/Sessions/Views/ActiveSessionView.swift` (880),
`Features/Schedule/Views/ScheduleTabView.swift` (578),
`Features/Exposures/Components/StepCardView.swift` (578),
`Features/Sessions/Views/MuscleRelaxationSessionView.swift` (571),
`Features/MainTab/Views/HomeView.swift` (558).
Смешаны UI + бизнес-логика + работа с БД + таймеры.
→ Выносить логику в ViewModel; дробить на подкомпоненты. `Components.swift` — разнести
по `Buttons/`, `Cards/`, `Navigation/`, `Modals/`.

### 8. Непоследовательный MVVM
Часть фич с ViewModel (Home, Schedule, BehavioralActivation), часть без (Exposures —
логика во вьюхах). `HomeViewModel.refresh()` принимает 11 параметров.
→ При доработках выносить бизнес-логику в ViewModel; рассмотреть передачу агрегата вместо
длинного списка параметров.

### 9. `BARoute` вне `AppRoute`
`Features/BehavioralActivation/BARoute.swift` — отдельный enum, который `NavigationRouter`
вынужден принимать как generic `Hashable` → размытая связность.
→ Включить `BARoute` кейсом в `AppRoute` (`case ba(BARoute)`).

---

## 🟡 Желательно

### 10. Дублирование UI-паттернов
4 вида row в `SettingsView` (navRow/actionRow/linkRow/infoRow), 3 одинаковых фильтр-меню
в BehavioralActivation, повторяющийся паттерн «сессия→результат→save» в трёх session-вьюхах.
→ Извлечь `SettingsRow`, `FilterMenu<Item>`, общий хелпер сохранения сессии.

### 11. Хардкод мимо дизайн-системы
~60+ мест с захардкоженными `.frame`/`cornerRadius`/`.font(.system(size:))`/RGB-цветами
вместо токенов (`Spacing`, `CornerRadius`, `AppTextStyle`, `AppColors`).
→ Заменять на токены по мере правок соответствующих экранов.

### 12. Дублирование данных-снимков
`ExerciseCompletion` хранит снимок полей из `ExerciseAssignment` (`exerciseType`,
`exposureId`, `*Type`, `activityId`) — при изменении assignment история показывает устаревшее.
→ Решить осознанно: ссылка + кэш только `displayTitle`, либо явная стратегия обновления снимка.

### 13. `NavigationRouter` — дублирование switch-case
По `switch tab` в `navigate`/`navigateBack` для каждого таба.
→ Заменить на `[AppTab: NavigationPath]`.

### 14. `ArticlesLoader` — небезопасный статический кэш
`cachedArticlesByLocalization` — mutable static, не обновляется при смене локали в рантайме.
→ Инвалидация кэша при смене локали / thread-safe доступ.

### 15. Прочее
- `SampleDataLoader` — нет дедупликации при повторной загрузке (риск дублей).
- `NotificationManager` — пересмотреть логику дней недели и `repeats: true`.
- `AppRouteView` грузит все `@Query`-наборы под отдельные маршруты (неэффективно на больших данных).
- Очистить `stale`-записи в `Localizable.xcstrings`.
