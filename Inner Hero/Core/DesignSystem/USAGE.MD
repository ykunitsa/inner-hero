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
| `AppColors.gray200` | `#E8E8EC` | Делители и **декоративные** края карточек |
| `AppColors.gray300` | `#D0D0D6` | Очень светлый серый (для текста непригоден) |
| `AppColors.gray400` | `#9898A8` | Плейсхолдеры, тихие декоративные точки — **не текст** (2.9:1) |
| `AppColors.gray600` | `#5A5A6A` | Tertiary text — единственный серый, проходящий 4.5:1 |
| `AppColors.controlBorder` | `#8E8E9A` / `#8E8E93` | Кольцо радио-точки. Больше нигде |

> ⚠️ **Нейминг серых:** номер НЕ отражает темноту — `gray400` (`#9898A8`)
> светлее, чем `gray600` (`#5A5A6A`). Выбирай по роли из комментария, не по числу.

#### Контрол опознаётся ЗАЛИВКОЙ, а не обводкой

Это главное правило форм. Обводок в них нет — вообще:

| | Как выглядит |
|---|---|
| Интерактивный контрол, не выбран | заливка `cardBackground`, обводки нет |
| Он же, выбран | заливка `accent.opacity(Opacity.mediumBackground)` |
| Сегмент выбран (`.segments`) | сплошной `accent` + `TextColors.onColor` |
| Цитата (`QuoteCard`) — read-only | заливки НЕТ, сквозь неё виден фон страницы |
| Делитель, край карточки (декор) | `gray200` + `BorderWidth.hairline` |

Отсюда же следует фон страницы: раз контрол — белая плашка, под ним нужен серый
(`.formBackground()`). Белое на белом не работает, а серый контрол на белой
странице читается как выключенный.

Обводка остаётся ровно в двух местах, и обе несут смысл, а не форму:
**кольцо радио-точки** (`controlBorder`, 3.24:1 — это индикатор состояния) и
**кольцо фокуса** у `AppTextEditor` (`accent`, `BorderWidth.emphasized`).

История, чтобы не ходить по кругу: сначала контуры были `gray200` 0.5pt —
**1.15:1**, физически не видно, контролы читались как задизейбленные. Потом
их подняли до 3:1 на всём подряд — форма стала похожа на вайрфрейм. Рабочий
ответ оказался третьим: аффорданс несёт заливка, порог 1.4.11 отрабатывает
там, где кодируется состояние.

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
| `.timerDisplay` | 56 | 700 | largeTitle | Секундомер сессии — единственный контент экрана (mono) |
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
scrollView.homeBackground()                          // фон-хаб: серый + верхнее свечение
Image(...).touchTarget()                             // зона касания ≥44×44
Image(...).iconContainer(size: IconSize.card, backgroundColor: AppColors.primaryLight)
```

### Фон экрана

Ровно три варианта, четвёртого нет:

| Экран | Фон | Почему |
|---|---|---|
| **Хаб** — набор отдельных карточек: 4 таба, настройки, онбординг | `.homeBackground()` | серый + акцентное свечение; карточки на нём *плавают* |
| **Форма** — экран с контролами: обе формы экспозиции и их шаги | `.formBackground()` | контролы — белые плашки на сером; серое поле на белом читается как disabled |
| **Одна задача** — экран вообще без контролов | `.background(AppColors.cardBackground.ignoresSafeArea())` | делить нечего, одна сплошная поверхность |

Раньше форма относилась к «одной задаче» и была белой. Это перестало быть верным,
когда контролы стали опознаваться **заливкой**: экран превратился в стопку
отдельных плашек, а плашкам нужна подложка. Плюс серая заливка на iOS означает
«неактивно», и белофоновая версия ровно так и читалась.

Промежуточного четвёртого серого заводить нельзя — именно он когда-то давал дрейф.
Форма берёт тот же `gray100`, что и всё остальное.

⚠️ Фон формы и `surface` у её `PinnedScrim` — **один и тот же цвет**. Разъедутся —
шапка и футер лягут полосами поперёк страницы.

Внутри одного флоу фон не меняется между шагами: у планируемой экспозиции
before / таймер / after — все три на `.formBackground()`.

### Пришпиленные шапка и кнопка

Форма скроллится под заголовком и под главной кнопкой. Подложку для обоих даёт
пара модификаторов:

```swift
.safeAreaInset(edge: .top)    { header.pinnedHeaderBackground() }
.safeAreaInset(edge: .bottom) { saveButton.pinnedFooterBackground() }
```

Кнопка вешается **инсетом, а не оверлеем в `ZStack`**. Оверлей не укорачивает
скроллируемую область, и если контент чуть выше экрана, последнее поле просто
не видно — оно лежит под непрозрачной кнопкой, и ничто не намекает, что там
что-то есть. Инсет отдаёт скроллу правильную высоту, а под кнопку контент
всё равно уезжает при прокрутке — для этого подложка и нужна.

Полоса **непрозрачная**, затухание вынесено целиком за её пределы. Градиент,
который гаснет внутри собственных границ, выглядит нормально под сплошным
текстом и сломанным под всем, у чего есть край: чипс или слайдер, пойманный в
полупрозрачной зоне, читается как обрезанный, а не как уехавший под шапку.
Именно так это и выглядело до правки.

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
HeroFeatureCard(subtitle: "While it's fresh", title: "Log an exposure",
                color: AppColors.primary, icon: "pencil")

// Строка лаунчера упражнений / ленты истории (вся строка — кнопка,
// стрелка декоративная)
ExerciseRow(title: "Breathing", meta: "Box · 10 min", icon: "wind") { open() }

// Цитата пользователю его же слов: напоминание предсказания (§3),
// сравнение с прогнозом BA (§6).
// Подпись рендерит ВЫЗЫВАЮЩИЙ — так она встаёт вровень с остальными
// SectionLabel экрана. Внутри контейнера её уезжало вправо на Spacing.sm,
// и левый край формы ломался на первом же блоке.
VStack(alignment: .leading, spacing: Spacing.xxs) {
    SectionLabel(text: "Your prediction · probably")
    QuoteCard(text: "It will overwhelm me...")
}

// Выбор с описанием (ступень ПМР, тип дыхания)
RadioCard(title: "7 groups", description: "~15 min · whole arm, face, torso...",
          isSelected: $selected)
```

### Инпуты форм (спека §3 — ситуативная форма и далее)

```swift
// Слайдер 0–10: тревога, оценки BA. Системный Slider, нейтральный цвет,
// текущее значение крупно над слайдером.
IntensitySlider(value: $anxiety)
    .accessibilityLabel(String(localized: "Anxiety level"))

// Чипсы-подсказки из прошлых сессий — тап подставляет текст в поле.
// Намеренно мелкие и НЕ капсулы (глиф-стрелка на тихом прямоугольнике),
// чтобы не путались с SelectableChip-тумблерами. Живут в одну строку
// с горизонтальным скроллом; края ряда гаснут, если есть продолжение.
SuggestionChipsRow(suggestions: chips) { field = $0 }

// Линейка с рисками и двумя маркерами: диапазон времени планируемой
// экспозиции (спека §3). Маркеры не пересекаются (max ≥ min + 1).
DurationRangeSlider(minMinutes: $rangeMin, maxMinutes: $rangeMax)  // 1...20

// Мультивыбор (охранное поведение)
ChipFlowLayout {
    SelectableChip(text: "Breathing", isSelected: $breathing)
    SelectableChip(text: "Phone", isSelected: $phone)
}

// Одиночный выбор из НАБОРА ФАКТОВ — карточки с радио-точкой:
SegmentedChoice(
    options: [
        ChoiceOption(value: Outcome.stayed, title: String(localized: "Stayed until the end")),
        ChoiceOption(value: Outcome.stayedHard, title: String(localized: "Wanted to leave, but stayed")),
        ChoiceOption(value: Outcome.left, title: String(localized: "Left early")),
    ],
    selection: $outcome
)
// .segments — только два-три очень коротких варианта («да/нет»):
SegmentedChoice(options: yesNo, selection: $answer, style: .segments)

// Одиночный выбор из ГРАДИЕНТА — шкала (см. ниже):
ScaleChoice(options: confidence, selection: $confidence)

// Многострочный ввод — белая плашка на сером фоне, обводка только на фокусе
AppTextEditor(text: $notes, placeholder: "Describe the situation…")
```

> **Грамматика форм:** *залитое* — интерактивное; *акцентно залитое* —
> выбрано; *голый текст с линейкой слева* (`QuoteCard`) — твои же слова,
> read-only. Не давай `QuoteCard` заливку: залитое на этих экранах читается
> как «сюда можно нажать», и цитата становится неотличима от поля ввода.

### Шкалы

У всех трёх контролов выбора значения одна и та же верхняя строка: **значение
крупно, управление под ним**. Ниже они расходятся, и намеренно:

| Контрол | Управление | Почему так |
|---|---|---|
| `IntensitySlider` | системный `Slider` | одно значение — нативный контрол даёт драг и VoiceOver даром |
| `ScaleChoice` | системный `Slider` с шагом в вариант | то же самое, только подписи вместо цифр |
| `DurationRangeSlider` | линейка `TickTrack` | два маркера, системный слайдер так не умеет |

Своя отрисовка (`TickTrack.swift`) осталась ровно там, где системный контрол не
справляется. Не тащи её в новые экраны «для единообразия» — единообразие тут
даёт как раз системный слайдер.

**`ScaleChoice` — только для ординальных наборов.** Насколько уверен, насколько
сильно, как часто. Для набора разных фактов («остался» / «ушёл раньше») —
`SegmentedChoice`: дорожка навязывает континуум, которого нет, а это враньё про
данные.

Что в `ScaleChoice` сделано намеренно и легко сломать:

- **Подписи концов видны всегда.** Крупное слово называет ответ, подписи — куда
  шкала идёт; без них направление теряется, потому что невыбранные варианты не
  показаны.
- **Выбор не опциональный.** Бегунок слайдера всегда где-то стоит, поэтому
  состояние «не отвечено» было бы бегунком, указывающим на значение, которого
  пользователь не выбирал. Вместо этого поле сеется вызывающей стороной — и
  сеется вариантом, который утверждает меньше всего.
  `PlannedExposureFlowViewModel` ставит `fiftyFifty`: поле кормит долю
  «предсказания не сбылись» (спека §5), и дефолт у края шкалы записал бы
  уверенность, которой никто не выражал. Побочный эффект: пропустивший вопрос
  пользователь всё равно запишет «fifty-fifty», и отличить это от осознанного
  ответа нечем.

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
