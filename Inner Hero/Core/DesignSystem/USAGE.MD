# Inner Hero — Design System

Полная документация по дизайн-системе. Актуальна для редизайна 2.0
(июль 2026, после чистки легаси-компонентов).

---

## Структура файлов

```
Inner Hero/Core/DesignSystem/
├── DesignSystem.swift      ← токены: цвета, спейсинг, радиусы, анимации
├── Typography.swift        ← шрифты, TextStyle enum, готовые Text-компоненты
├── ViewModifiers.swift     ← .cardStyle(), .heroCardStyle(), .pageBackground() и др.
├── Components.swift        ← готовые UI-компоненты (кнопки, карточки, инпуты)
└── HomeBackground.swift    ← .homeBackground() — фон главных экранов
```

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

| Токен | Light | Использование |
|-------|-------|---------------|
| `AppColors.primary` | `#E53726` | CTA, hero-карточки, акцент |
| `AppColors.primaryDark` | `#C42D1E` | Pressed/hover состояние |
| `AppColors.primaryLight` | `#FDECEA` | Фон badge, icon-container |
| `AppColors.accent` | `#6B5CE7` | Инпуты (слайдер, чипсы, сегменты) |
| `AppColors.accentLight` | `#EEF0FD` | Фон выбранного состояния |
| `AppColors.positive` | `#27AE60` | Дыхание, success |
| `AppColors.black` | `#1A1A1A` | Основные CTA-кнопки |
| `AppColors.cardBackground` | `#FFF` / `#2C2C2E` | Поверхность карточек (light/dark) |
| `AppColors.gray100` | `#F4F4F6` | Фон страниц |
| `AppColors.gray200` | `#E8E8EC` | Делители, бордеры карточек |
| `AppColors.gray300` | — | Disabled-бордеры (слишком светлый для текста) |
| `AppColors.gray400` | `#9898A8` | Secondary text, плейсхолдеры |
| `AppColors.gray600` | — | Tertiary text |

> ⚠️ **Нейминг серых:** номер НЕ отражает темноту. `gray400` — более тёмный
> текстовый серый, `gray600` — светлее. Выбирай по роли из комментария.

### Семантические цвета

```swift
AppColors.State.success  // зелёный
AppColors.State.warning  // оранжевый
AppColors.State.error    // тёмно-красный StateError — НЕ равен primary:
                         // ошибка не должна выглядеть как CTA
AppColors.State.info     // синий
```

### Шкала тревоги — намеренно БЕЗ цвета

Функции `anxietyColor` больше нет. Шкала 0–10 измеряет только интенсивность
(спека §3): зелёно-красная раскраска кодировала бы оценку «высокая тревога =
плохо», что противоречит модели inhibitory learning (успех = «остался», а не
«тревога снизилась»). Инпуты интенсивности используют один нейтральный цвет
(`AppColors.accent`).

### Текстовые цвета

```swift
TextColors.primary          // .primary — адаптируется к dark mode
TextColors.secondary        // .secondary
TextColors.tertiary         // secondary * 0.65
TextColors.onColor          // белый — для текста поверх цветных карточек
TextColors.onColorSecondary // белый * 0.8 — subtitle на цветном фоне
TextColors.onBlack          // контент на AppColors.black — инвертируется
                            // вместе с поверхностью (в dark AppBlack светлый!)
```

> ⚠️ На поверхности `AppColors.black` никогда не клади чистый `.white` —
> в тёмной теме AppBlack становится почти белым и контент исчезает.
> Только `TextColors.onBlack`.

---

## 2. Типографика (`Typography.swift`)

**Все стили масштабируются с Dynamic Type**: размер привязан к системному
текст-стилю через `@ScaledMetric` внутри `.appFont(...)`. Размеры в таблице —
для дефолтного (Large) размера контента.

```swift
Text("Inner Hero").appFont(.h1)
Text("Box breathing · 10 min").appFont(.small).foregroundStyle(TextColors.secondary)
```

| Style | Размер | Вес | Анкер | Использование |
|-------|--------|-----|-------|---------------|
| `.display` | 34 | 700 | largeTitle | Онбординг, сплэш |
| `.h1` | 28 | 700 | title | Заголовок экрана |
| `.h2` | 22 | 700 | title2 | Заголовок карточки |
| `.h3` | 17 | 600 | headline | Подзаголовок секции |
| `.body` | 17 | 400 | body | Основной текст (= системный body iOS) |
| `.bodyMedium` | 17 | 500 | body | Выделенный основной текст |
| `.small` | 13 | 400 | footnote | Мета, теги, дата |
| `.smallMedium` | 13 | 500 | footnote | Badge, active label |
| `.caption` | 11 | 600 | caption2 | ALL CAPS заголовки секций |
| `.mono` | 15 | 700 | subheadline | Таймер compact (mono) |
| `.monoLarge` | 28 | 700 | title | Таймер large (mono) |
| `.statValue` | 20 | 700 | title3 | Числовые доли «6 из 7» (mono) |
| `.buttonPrimary` | 16 | 600 | callout | Текст основной кнопки |
| `.buttonSmall` | 14 | 600 | subheadline | Компактная кнопка |

> Минимальный размер шрифта — 11 (`.caption`). Ничего меньше.
> `AppTextStyle.fixedFont` существует для редких мест, где ViewModifier
> неприменим, — он НЕ масштабируется, используй осознанно.

### Готовые Text-компоненты

```swift
AppTitle(text: "Exercises")
CardTitle(text: "Guided Breathing")
MetaLabel(text: "Box · 10 min")
SectionLabel(text: "Your prediction") // выводится как CAPS
```

---

## 3. Спейсинг (`DesignSystem.swift`)

4-point grid. Всегда используй имена, не числа.

```swift
.padding(.horizontal, Spacing.sm)    // 16
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
| `Spacing.xxxl` | 48 |

---

## 4. Радиусы (`DesignSystem.swift`)

```swift
RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
```

| Токен | pt | Использование |
|-------|----|---------------|
| `CornerRadius.sm` | 8 | Icon container, badge |
| `CornerRadius.md` | 14 | Radio card, quote card, инпуты |
| `CornerRadius.lg` | 22 | Стандартная карточка |
| `CornerRadius.xl` | 28 | Hero card |
| `CornerRadius.pill` | 999 | Кнопки, капсулы |

---

## 5. View Modifiers (`ViewModifiers.swift`)

```swift
content.cardStyle()                                  // карточка-поверхность с тенью (light/dark)
content.heroCardStyle(color: AppColors.primary)      // цветная hero-карточка
content.accentCardStyle(accentColor: AppColors.accent) // лёгкий тинт + цветной бордер
scrollView.pageBackground()                          // серый фон страницы
scrollView.homeBackground()                          // фон с верхним свечением (главные экраны)
Image(...).touchTarget()                             // зона касания ≥44×44
Image(...).iconContainer(size: IconSize.card, backgroundColor: AppColors.primaryLight)
```

---

## 6. Компоненты (`Components.swift`)

### Кнопки

```swift
PrimaryButton(title: "Start") { ... }
PrimaryButton(title: "Save", color: AppColors.primary, isLoading: isSaving) { ... }
// Внутри NavigationLink — label-версия, чтобы тап обрабатывал link:
NavigationLink(value: route) { PrimaryButtonLabel(title: "Start session") }

// ⚠️ В .toolbar НЕ используй CircleButton: iOS 26 сам оборачивает элементы
// тулбара в стеклянную капсулу, и кастомный фон внутри неё растягивается.
// В тулбаре — обычный Button { } label: { Image(systemName:) }.
CircleButton(systemImage: "gearshape") { openSettings() }  // вне тулбаров; дефолт — круглое стекло
CircleButton(systemImage: "xmark",                         // круг-«закрыть» в стиле системных шитов
             background: AppColors.gray100) { dismiss() }
CircleButton(systemImage: "arrow.up",                      // акцентный тёмный вариант
             background: AppColors.black,
             foreground: TextColors.onBlack) { submit() }
SessionPlayPauseCircleButton(isPlaying: isPlaying) { toggle() } // тёмный chrome сессий
```

### Карточки

```swift
// Единственная акцентная карточка экрана («Записать экспозицию»).
// Всегда доступна — без dismiss и избранного.
HeroFeatureCard(subtitle: "Just happened", title: "Log an exposure",
                color: AppColors.primary, icon: "square.and.pencil")

// Строка лаунчера упражнений / ленты истории (вся строка — кнопка,
// стрелка декоративная)
ExerciseRow(title: "Breathing", meta: "Box · 10 min", icon: "wind") { open() }

// Цитата пользователю его же слов: напоминание предсказания (§3),
// сравнение с прогнозом BA (§6)
QuoteCard(label: "Your prediction", text: "It will overwhelm me...")

// Выбор с описанием (ступень ПМР, тип дыхания)
RadioCard(title: "7 groups", description: "~15 min · whole arm, face, torso...",
          isSelected: $selected)
```

### Инпуты форм (спека §3 — ситуативная форма и далее)

```swift
// Слайдер 0–10: тревога, оценки BA. Нейтральный цвет, значение в бегунке.
IntensitySlider(value: $anxiety)
    .accessibilityLabel(String(localized: "Anxiety"))

// Чипсы-подсказки из прошлых сессий — тап подставляет текст в поле
ChipFlowLayout {
    ForEach(suggestions, id: \.self) { s in
        SuggestionChip(text: s) { situation = s }
    }
}

// Мультивыбор (охранное поведение)
ChipFlowLayout {
    SelectableChip(text: "Breathing", isSelected: $breathing)
    SelectableChip(text: "Phone", isSelected: $phone)
}

// Сегментный выбор, один тап. Вертикальный — для длинных подписей:
SegmentedChoice(
    options: [
        ChoiceOption(value: Outcome.stayed, title: String(localized: "Stayed until the end")),
        ChoiceOption(value: Outcome.stayedHard, title: String(localized: "Wanted to leave, but stayed")),
        ChoiceOption(value: Outcome.left, title: String(localized: "Left early")),
    ],
    selection: $outcome
)
// Горизонтальный — для коротких («да/нет»):
SegmentedChoice(options: yesNo, selection: $answer, axis: .horizontal)

// Многострочный ввод
AppTextEditor(text: $notes, placeholder: "Describe the situation...", minHeight: 120)
```

### Прочее

```swift
AppBadge(text: "Situational", style: .neutral)   // error/success/neutral/accent/warning
SectionHeader(title: "Exercises", onSeeAll: { }) // или без onSeeAll
SectionLabel(text: "Safety behaviors")           // ALL CAPS метка секции

// Верхняя панель полноэкранного флоу: X + заголовок + категория + шестерёнка
ExerciseStepHeader(title: "Guided Breathing", category: "RELAXATION",
                   onBack: { dismiss() }, onSettings: { show = true })

// Нижняя капсула сессии: назад | таймер | действие
SessionFlowBottomPill(
    left:   { CircleButton(...) },
    center: { Text(time).appFont(.mono) },
    right:  { SessionPlayPauseCircleButton(...) }
)

BreathingCircle(phase: .inhale, color: AppColors.positive)
// ⚠️ Для квадратного дыхания (4-4-4-4) потребуется 4-я фаза
// (задержка после выдоха) — доработка в §11.3, см. таск DS-10.
```

---

## 7. Анимации

```swift
withAnimation(AppAnimation.standard) { ... }  // 0.22 easeOut — дефолт
withAnimation(AppAnimation.spring)   { ... }  // пружина для переключений
withAnimation(AppAnimation.fast)     { ... }  // 0.14 — мелкие тумблеры
withAnimation(AppAnimation.slow)     { ... }  // 0.40 — крупные переходы
```

Кодекс §7: анимации тонкие и быстрые, салютов и празднований не бывает.
Хаптика — только функциональная: `HapticFeedback.selection()` на выбор
значения, `.notification(.success)` на сохранение.

---

## 8. Размеры иконок

| Токен | pt | Использование |
|-------|----|---------------|
| `IconSize.hero` | 56 | Hero-карточка |
| `IconSize.card` | 44 | List row, контейнер |
| `IconSize.action` | 36 | Круглая стрелка в ExerciseRow |
| `IconSize.inline` | 24 | Navigation |
| `IconSize.glyph` | 17 | SF Symbol font size |
| `IconSize.fieldGlyph` | 15 | Глиф рядом с body-текстом поля |
| `IconSize.emptyState` | 40 | Иллюстрация пустого состояния |

---

## 9. Правила и Anti-patterns

### ✅ Делай так

```swift
.foregroundStyle(AppColors.primary)      // цвета — токены
Text("Hello").appFont(.body)             // шрифты — .appFont()
.padding(Spacing.sm)                     // спейсинг — Spacing.*
content.cardStyle()                      // карточки — модификаторы
Image(...).touchTarget()                 // зоны касания — явно
```

### ❌ Не делай так

```swift
Color(hex: "#E53726"); Color.red; Color(red: 0.95, ...)  // хардкод цветов
.fill(.white)                       // поверхность карточки — только cardBackground
.font(.system(size: 15))            // хардкод шрифта — не масштабируется
.padding(16)                        // хардкод паддингов
Image(systemName: "xmark")          // без touchTarget()
```

Не существует в этой системе (и не должно появиться): бейджи непрочитанного,
стрики, прогресс-кольца по дням, конфетти, «мотивирующие» тексты — кодекс §8.
