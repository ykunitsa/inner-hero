# CBT Tools — Design System

Полная документация по дизайн-системе. Актуальна для редизайна приложения.

---

## Структура файлов

```
Inner Hero/Core/DesignSystem/
├── DesignSystem.swift      ← токены: цвета, спейсинг, радиусы, анимации
├── Typography.swift        ← шрифты, TextStyle enum, готовые Text-компоненты
├── ViewModifiers.swift     ← .cardStyle(), .heroCardStyle(), .pageBackground() и др.
└── Components.swift        ← готовые UI-компоненты (кнопки, карточки, badge и др.)
```

---

## Подключение

Файлы уже лежат в той же группе `Core/DesignSystem` — дополнительных `import` не нужно.
Все enum'ы и компоненты доступны глобально в рамках таргета.

---

## 1. Цвета (`DesignSystem.swift`)

### Правило: никогда не используй raw hex в View-слое.

```swift
// ✅ Правильно
.foregroundStyle(AppColors.primary)
.background(AppColors.gray100)

// ❌ Неправильно
.foregroundStyle(Color(hex: "#E53726"))
.background(Color(red: 0.96, green: 0.96, blue: 0.96))
```

### Палитра

| Токен | Hex | Использование |
|-------|-----|---------------|
| `AppColors.primary` | `#E53726` | CTA, hero-карточки, акцент |
| `AppColors.primaryDark` | `#C42D1E` | Pressed/hover состояние |
| `AppColors.primaryLight` | `#FDECEA` | Фон badge, icon-container |
| `AppColors.accent` | `#6B5CE7` | Эмоциональный поток, mood |
| `AppColors.accentLight` | `#EEF0FD` | Фон selected emotion cell |
| `AppColors.positive` | `#27AE60` | Breathing, success, прогресс |
| `AppColors.black` | `#1A1A1A` | Основные CTA-кнопки |
| `AppColors.gray100` | `#F4F4F6` | Фон страниц |
| `AppColors.gray200` | `#E8E8EC` | Делители, бордеры карточек |
| `AppColors.gray400` | `#9898A8` | Secondary text |

### Семантические цвета

```swift
AppColors.State.success  // зелёный
AppColors.State.warning  // оранжевый
AppColors.State.error    // красный (= primary)
AppColors.State.info     // синий
```

### Текстовые цвета

```swift
TextColors.primary          // .primary — адаптируется к dark mode
TextColors.secondary        // .secondary
TextColors.tertiary         // secondary * 0.65
TextColors.onColor          // белый — для текста поверх цветных карточек
TextColors.onColorSecondary // белый * 0.8 — subtitle на цветном фоне
```

---

## 2. Типографика (`Typography.swift`)

### Использование

```swift
Text("CBT Tools")
    .appFont(.h1)

Text("Identify your cognitive distortions")
    .appFont(.h2)
    .foregroundStyle(TextColors.onColor)

Text("5 min · Reframing")
    .appFont(.small)
    .foregroundStyle(TextColors.secondary)
```

### Таблица стилей

| Style | Размер | Вес | Использование |
|-------|--------|-----|---------------|
| `.display` | 34px | 700 | Онбординг, сплэш |
| `.h1` | 28px | 700 | Заголовок экрана |
| `.h2` | 22px | 700 | Заголовок карточки |
| `.h3` | 17px | 600 | Подзаголовок секции |
| `.bodyLarge` | 17px | 400 | Важный основной текст |
| `.body` | 15px | 400 | Основной текст |
| `.bodyMedium` | 15px | 500 | Выделенный основной текст |
| `.small` | 13px | 400 | Мета, теги, дата |
| `.smallMedium` | 13px | 500 | Badge, active label |
| `.caption` | 11px | 600 | ALL CAPS заголовки секций |
| `.mono` | 15px | 700 | Таймер compact |
| `.monoLarge` | 28px | 700 | Таймер large |
| `.buttonPrimary` | 16px | 600 | Текст основной кнопки |

> **Минимальный размер шрифта в интерфейсе — 11px (`.caption`).** Ничего меньше.

### Готовые Text-компоненты

```swift
AppTitle(text: "CBT Tools")
CardTitle(text: "Guided Breathing")
MetaLabel(text: "5 min · Reframing")
SectionLabel(text: "Your Recorded Thought") // выводится как CAPS
```

---

## 3. Спейсинг (`DesignSystem.swift`)

4-point grid. Всегда используй имена, не числа.

```swift
.padding(.horizontal, Spacing.sm)    // 16
.padding(.vertical, Spacing.xs)      // 12
VStack(spacing: Spacing.md)          // 20
```

| Токен | pt |
|-------|----|
| `Spacing.xxxs` | 4 |
| `Spacing.xxs` | 8 |
| `Spacing.xs` | 12 |
| `Spacing.sm` | 16 |
| `Spacing.md` | 20 |
| `Spacing.lg` | 24 |
| `Spacing.xl` | 32 |
| `Spacing.xxl` | 40 |

---

## 4. Радиусы (`DesignSystem.swift`)

```swift
RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
```

| Токен | pt | Использование |
|-------|----|---------------|
| `CornerRadius.sm` | 8 | Icon container, badge |
| `CornerRadius.md` | 14 | Radio card, thought card |
| `CornerRadius.lg` | 22 | Стандартная карточка |
| `CornerRadius.xl` | 28 | Hero card |
| `CornerRadius.pill` | 999 | Кнопки, progress bar |

---

## 5. View Modifiers (`ViewModifiers.swift`)

### `.cardStyle()` — белая карточка с тенью

```swift
VStack { /* ... */ }
    .cardStyle()

// Кастомизация:
VStack { /* ... */ }
    .cardStyle(cornerRadius: CornerRadius.md, padding: Spacing.sm)
```

### `.heroCardStyle()` — цветная hero-карточка

```swift
VStack { /* ... */ }
    .heroCardStyle(color: AppColors.primary)
```

### `.accentCardStyle()` — лёгкий тинт с цветным бордером

```swift
VStack { /* ... */ }
    .accentCardStyle(accentColor: AppColors.accent)
```

### `.pageBackground()` — фон страницы

```swift
NavigationStack {
    ScrollView { /* ... */ }
        .pageBackground()
}
```

### `.progressBar()`

```swift
HStack { /* ... */ }
    .progressBar(progress: 0.4, color: AppColors.primary)
```

### `.touchTarget()` — минимальная зона касания 44×44

```swift
Image(systemName: "xmark")
    .touchTarget()
```

### `.iconContainer()` — контейнер иконки

```swift
Image(systemName: "doc.text")
    .iconContainer(
        size: IconSize.card,
        backgroundColor: AppColors.primaryLight
    )
```

### `.shimmer()` — skeleton loading

```swift
RoundedRectangle(cornerRadius: CornerRadius.lg)
    .fill(AppColors.gray200)
    .frame(height: 80)
    .shimmer()
```

---

## 6. Компоненты (`Components.swift`)

### PrimaryButton

```swift
PrimaryButton(title: "Continue") {
    // action
}

// С кастомным цветом:
PrimaryButton(title: "Start Exercise", color: AppColors.primary) {
    // action
}

// Состояние загрузки:
PrimaryButton(title: "Saving...", isLoading: true) {}
```

### CircleButton

```swift
CircleButton(
    systemImage: "xmark",
    background: AppColors.primaryOverlay,
    foreground: .white
) { dismiss() }
```

### HeroFeatureCard

```swift
HeroFeatureCard(
    subtitle: "Afternoon Check-in",
    title: "Identify your cognitive distortions",
    color: AppColors.primary,
    icon: "sun.max",
    onDismiss: { /* skip */ },
    onFavourite: { /* save */ }
)
```

### ExerciseRow

```swift
ExerciseRow(
    title: "Thought Record",
    meta: "5 min · Reframing",
    icon: "doc.text",
    iconColor: AppColors.primary
) {
    // navigate
}
```

### RadioCard

```swift
@State private var selected = false

RadioCard(
    title: "Catastrophizing",
    description: "Expecting the worst-case scenario to happen.",
    isSelected: $selected
)
```

### EmotionCell (в сетке 3 колонки)

```swift
@State private var selectedEmotion: String? = nil

LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: Spacing.xxs) {
    ForEach(emotions) { emotion in
        EmotionCell(
            emoji: emotion.emoji,
            label: emotion.label,
            isSelected: Binding(
                get: { selectedEmotion == emotion.id },
                set: { if $0 { selectedEmotion = emotion.id } }
            ),
            accentColor: AppColors.accent
        )
    }
}
```

### AppBadge

```swift
AppBadge(text: "Fortune Telling", style: .error, systemImage: "exclamationmark.triangle")
AppBadge(text: "Completed", style: .success)
AppBadge(text: "5 min", style: .neutral)
```

### TopTabBar

```swift
@State private var selectedTab = 0

TopTabBar(tabs: ["Daily", "Journal", "Discover"], selection: $selectedTab)
```

### StepProgressBar

```swift
// Прогресс 2 из 5
StepProgressBar(current: 2, total: 5, color: AppColors.primary)
    .frame(height: 4)
```

### RecordedThoughtCard

```swift
RecordedThoughtCard(
    text: "\"I made one mistake in the presentation, now my boss thinks I'm completely incompetent.\""
)
```

### BreathingCircle

```swift
BreathingCircle(phase: .inhale, color: AppColors.positive)
    .frame(width: 160, height: 160)
```

---

## 7. Анимации

```swift
withAnimation(AppAnimation.standard) { /* state change */ }
withAnimation(AppAnimation.spring)   { /* springy UI */  }
withAnimation(AppAnimation.fast)     { /* quick toggle */ }
```

---

## 8. Размеры иконок

```swift
Image(systemName: "sun.max")
    .font(.system(size: IconSize.glyph))   // 17px — inline
    .frame(width: IconSize.card, height: IconSize.card) // 44px — list row
```

| Токен | pt | Использование |
|-------|----|---------------|
| `IconSize.hero` | 56 | Hero-карточка |
| `IconSize.card` | 44 | List row, контейнер |
| `IconSize.action` | 36 | Arrow-кнопка |
| `IconSize.inline` | 24 | Navigation |
| `IconSize.glyph` | 17 | SF Symbol font size |

---

## 9. Правила и Anti-patterns

### ✅ Делай так

```swift
// Цвета — всегда через токены
.foregroundStyle(AppColors.primary)
.background(AppColors.gray100)

// Типографика — всегда через .appFont()
Text("Hello").appFont(.body)

// Спейсинг — всегда через Spacing.*
.padding(Spacing.sm)
VStack(spacing: Spacing.xs)

// Карточки — через модификаторы
content.cardStyle()

// Touch target — явно
Image(...).touchTarget()
```

### ❌ Не делай так

```swift
// Хардкод цветов
Color(hex: "#E53726")
Color.red
Color(red: 0.95, ...)

// Хардкод размеров шрифта
.font(.system(size: 15))

// Хардкод паддингов
.padding(16)
.padding(.horizontal, 20)

// Маленькие tap-зоны
Image(systemName: "xmark")  // без touchTarget()
```

---

## 10. Пример экрана

```swift
struct DailyView: View {
    @State private var tabIndex = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Tab bar
                TopTabBar(
                    tabs: ["Daily", "Journal", "Discover"],
                    selection: $tabIndex
                )

                // Hero card
                HeroFeatureCard(
                    subtitle: "Afternoon Check-in",
                    title: "Identify your cognitive distortions",
                    color: AppColors.primary,
                    icon: "sun.max",
                    onDismiss: {},
                    onFavourite: {}
                )

                // Section
                HStack {
                    CardTitle(text: "Exercises")
                    Spacer()
                    Button("See All") {}
                        .appFont(.small)
                        .foregroundStyle(TextColors.secondary)
                }

                VStack(spacing: Spacing.xxs) {
                    ExerciseRow(title: "Thought Record", meta: "5 min · Reframing", icon: "doc.text") {}
                    ExerciseRow(title: "Guided Breathing", meta: "3 min · Relaxation", icon: "wind") {}
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.md)
        }
        .pageBackground()
        .navigationTitle("CBT Tools")
    }
}
```
