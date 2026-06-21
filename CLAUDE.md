# Inner Hero — Project Guide

КПТ-компаньон для тревожности (iOS). Все данные локальные, без аккаунтов и сети.
Экспозиции, дыхание, релаксация, заземление, поведенческая активация, расписание,
база знаний.

> Этот файл загружается в контекст каждой сессии. Держи его как **карту**, а не как
> копию кода: он должен помогать сразу идти в нужный файл, а не пересказывать его.
> Обновляй при значимых изменениях архитектуры/конвенций.

---

## Язык и общение

- **Общение с пользователем — на русском.** Объяснения, ответы, summary — по-русски.
- **Язык кода и исходных строк — английский (primary).** `Localizable.xcstrings`
  имеет `sourceLanguage: en`. Все новые user-facing строки **сначала пишутся на
  английском** ключом `String(localized: "English text")`, а русский добавляется как
  **перевод** в `.xcstrings`. Русский — secondary/translation, не source.
  ⚠️ Частая ошибка: создавать новые лейблы/строки сразу на русском в коде. Так делать
  не надо — source всегда английский, перевод живёт в `.xcstrings`.
- Идентификаторы, имена типов, комментарии в коде — английские.

---

## Стек

| Область       | Выбор                          |
|---------------|--------------------------------|
| Платформа     | iOS 26+                        |
| UI            | SwiftUI (без UIKit)            |
| Данные        | SwiftData (локально, без сети) |
| Состояние     | `@Observable` / `@Query` / `@Environment` (Observation Framework, не Combine) |
| Локализация   | `Localizable.xcstrings` (EN source, RU translation) |

Только SwiftUI и актуальный Swift. **UIKit не использовать.**

---

## Команды

```bash
# Сборка под симулятор
xcodebuild -project "Inner Hero.xcodeproj" -scheme "Inner Hero" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Тесты
xcodebuild -project "Inner Hero.xcodeproj" -scheme "Inner Hero" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

- Единственная схема: **`Inner Hero`**. Таргеты: `Inner Hero`, `Inner HeroTests`, `Inner HeroUITests`.
- Конфигурации: `Debug`, `Release`.

---

## Карта проекта

```
Inner Hero/
├── App/
│   ├── Inner_HeroApp.swift        # Точка входа, ModelContainer, onboarding/sample data
│   └── Schema/                    # SchemaV1, SchemaV2, AppMigrationPlan (миграции SwiftData)
├── Core/
│   ├── DesignSystem/              # ⭐ Токены и компоненты — ВСЕГДА начинать отсюда для UI
│   ├── Navigation/                # NavigationRouter, AppRoute, AppRouteView
│   ├── Components/                # Общие компоненты (Charts, Modals, Schedule)
│   └── Utilities/                 # BreathingController, StepTimerController, Haptics, Export
├── Features/                      # Фичи по модулям (см. ниже)
│   └── <Feature>/{Views,ViewModels,Components}/
├── Models/                        # @Model SwiftData + Extensions/ + Predefined/
├── Services/                      # Stateless-хелперы и менеджеры
└── Resources/                     # Localizable.xcstrings, ассеты
```

### Фичи (`Features/`)
- **MainTab** — Home (сводка), таб-навигация.
- **Schedule** — планирование упражнений по дням/времени, отметки выполнения.
- **Exposures** — экспозиционная терапия: CRUD, шаги, таймеры, session-flow, прогресс.
- **Sessions** — UI сессий дыхания / релаксации / заземления / экспозиции.
- **BehavioralActivation** — списки активностей и сессии (новейший модуль, активно меняется).
- **KnowledgeCenter** — статьи (поиск, категории).
- **Onboarding** — первый запуск + дисклеймер.
- **Settings** — Appearance / Privacy (app lock, PIN/биометрия) / Data (export/reset) / About.

---

## Конвенции

### Дизайн-система (`Core/DesignSystem/`) — обязательна
Не хардкодить размеры/цвета/шрифты. Использовать токены:

- **Цвета:** `AppColors.*` (`DesignSystem.swift:8`) — `AppColors.primary`, `AppColors.positive` и т.п. Никаких `Color(red:green:blue:)` и `.blue`/`.green` в фичах.
- **Отступы:** `Spacing.*` (`:73`) — вместо `padding(16)`/`spacing: 12`.
- **Радиусы:** `CornerRadius.*` (`:93`) — вместо `cornerRadius: 20`.
- **Иконки/тач-таргеты:** `IconSize.*` (`:121`), `TouchTarget.*` (`:113`).
- **Прозрачности/тени:** `Opacity.*` (`:140`).
- **Анимации/тайминги:** `AppAnimation.*` (`:170`), `InteractionTiming.*` (`:191`).
- **Типографика:** `.appFont(.body)` и т.д. через `AppTextStyle` (`Typography.swift:14`).
  Стили: `display, h1, h2, h3, bodyLarge, body, bodyMedium, small, smallMedium,
  caption, mono, monoLarge, statValue, buttonPrimary, buttonSmall, navItem, navItemActive`.
  Вместо `.font(.system(size: 14, weight: .semibold))` — подобрать стиль из `AppTextStyle`.
- Переиспользуемые компоненты — в `Components.swift` (большой файл; перед созданием
  нового компонента проверить, нет ли уже готового: `PrimaryButton`, `CircleButton`,
  `ExerciseRow`, `RadioCard`, `HeroFeatureCard`, навигационные пиллы и т.д.).
- Общие модификаторы — в `ViewModifiers.swift` (`cardStyle`, `heroCardStyle`, `touchTarget`, `pageBackground`, ...).

### Локализация
- User-facing текст: `String(localized: "English source")`. Source — английский.
- Перевод (RU) добавляется в `Localizable.xcstrings`, не в код.
- Форматные строки: `String(format: String(localized: "Completed %1$d of %2$d"), a, b)`.
- Не хардкодить отображаемый текст напрямую в `Text("...")` (исключение — данные/идентификаторы).

### Навигация
- Централизованный `NavigationRouter` (`@Observable @MainActor`), по `NavigationPath` на таб.
- Маршруты — в `AppRoute` (enum). Роутинг — `switch` в `AppRouteView`.
- `BARoute` — отдельный enum для BehavioralActivation (см. TECH_DEBT — это считается долгом).

### MVVM
- ViewModels: `@Observable @MainActor`, без прямого UIKit/глобалов.
- ⚠️ MVVM применён **непоследовательно**: у части фич есть ViewModel (Home, Schedule,
  BehavioralActivation), у части (Exposures) логика живёт во вьюхах. При новой работе —
  тяготеть к выносу бизнес-логики в ViewModel, а не наращивать «массивные вьюхи».

### SwiftData
- `@Model`-классы — в `Models/`: `Exposure`, `ExposureSessionResult`, `ActivationTask`,
  `ActivationCategory`, `ActivationSession`, `ExerciseAssignment`, `ExerciseCompletion`,
  `FavoriteExercise`, `BreathingSessionResult`, `RelaxationSessionResult`, `GroundingSessionResult`.
- Изменение моделей → **обязательно** новая версия схемы + стадия в `AppMigrationPlan`
  (см. `App/Schema/`). Не менять существующие схемы «на месте».
- Локализуемые/предзаданные данные моделей — в `Models/Extensions/` и `Models/Predefined/`.
- Завершение упражнения — только через `Services/SessionCompletionService` (идемпотентно,
  по `uniqueKey`). Не создавать `ExerciseCompletion` вручную.

### Сервисы (`Services/`)
Stateless-хелперы / менеджеры: `SessionCompletionService`, `NotificationManager` (`@MainActor`),
`FavoritesService`, `ArticlesLoader`/`ArticlesStore`, `SampleDataLoader`. Бизнес-логику,
работающую с `ModelContext`, держать здесь, а не во вьюхах.

### Concurrency
- `async/await` + `@MainActor`. GCD не вводить.
- Долгоживущие `Task` и `Timer` — отменять в `onDisappear` (сейчас это соблюдается не везде, см. TECH_DEBT).

---

## Перед началом работы

1. Для UI-задач — сперва посмотреть `Core/DesignSystem/` (токены и готовые компоненты).
2. Для работы с данными — посмотреть нужный `@Model` и `App/Schema/`.
3. Новый user-facing текст — английский ключ + перевод в `.xcstrings`.
4. Заглянуть в **[TECH_DEBT.md](TECH_DEBT.md)** — известные слабые места и «осторожно здесь»,
   чтобы не опираться на них как на образец и не ломать договорённости.

## Чего не делать
- Не использовать UIKit.
- Не хардкодить цвета/отступы/шрифты вместо токенов дизайн-системы.
- Не писать новые отображаемые строки на русском в коде (source — английский).
- Не менять существующие версии схемы SwiftData без новой миграции.
- Не плодить «массивные вьюхи» — выносить логику в ViewModel/компоненты.
