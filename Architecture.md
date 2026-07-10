# GlassBarProto — як ми зробили нативний Liquid Glass таб-бар у React Native

Це док про одне питання: **чи можна зробити 1:1 нативний Liquid Glass морф чисто в React Native?**

Спойлер: ні. І це не «ми не змогли», це дизайн платформи — Apple віддала matched-geometry морф скла тільки SwiftUI. Тому в нас гібрид: сам бар — маленький нативний SwiftUI-компонент, а все інше — звичайний RN. Нижче — як ми до цього дійшли і як воно влаштоване.

*(Рісьорч — липень 2026, все перевірено по першоджерелах: Apple docs, сорси бібліотек, GitHub issues. Лінки в кінці.)*

---

## 1. Історія пошуку: чотири варіанти

### Варіант A: «може, стандартний таб-бар потягне?» — ні ❌

Перше, що перевірили: react-navigation native tabs, react-native-bottom-tabs від Callstack, Expo NativeTabs і сам UIKit `UITabBarController`.

Все впирається в одне: **жодна з цих обгорток не пускає кастомні в'юхи всередину бара.** Кастомізація — іконки, лейбли, бейджі, і все. А на рівні UIKit: той красивий морф search-таба з Apple Music — це системна поведінка search-ролі (`UISearchTab`), вона розгортається тільки в пошуковий філд і більше ні в що. Єдиний паблік-кноб — `automaticallyActivatesSearch`. API «таб розгортається в бабл з трьома кастомними під-табами» просто не існує.

Тобто наша інтеракція через `UITabBarController` не виражається в принципі. Потрібен повністю кастомний бар.

### Варіант B: «ок, кастомний бар чисто в RN — glass-бібліотеки + Reanimated» — теж ні ❌

Є дві пристойні лібки: `@callstack/liquid-glass` і `expo-glass-effect`. Обидві обгортають один і той самий UIKit-примітив: `UIVisualEffectView` + `UIGlassEffect`, а контейнер — `UIGlassContainerEffect`, у якого рівно один параметр: `spacing`.

Що вони вміють: **proximity-merge** — шейпи, які зближуються ближче ніж spacing, красиво зливаються. Це працює й анімується (у Callstack є офіційне демо з драгом кружечка).

Чого вони НЕ вміють — і це вбивця: **ID-matched морфа немає.** `glassEffectID` + `@Namespace` + `.glassEffectTransition(.matchedGeometry)` — це SwiftUI-only API. Ми перевірили по Apple docs: UIKit-овий `UIGlassEffect` має рівно три члени — `init(style:)`, `isInteractive`, `tintColor`. Все. В UIKit «морф» = вручну анімувати фрейми, поки не злипнуться, а вставка/зникнення елемента (наша кнопка «+») стрибає, а не морфиться.

Бонусом — задокументовані міни: анімація opacity до ~0 **назавжди** вбиває глас-рендер (callstack #27/#33, expo #41024 — закритий як "Upstream: iOS"), флікер на маунті, нестабільність у Release. І жодного публічного демо морфа width/height на 120Hz ніхто не показав.

Вердикт: fidelity ~2.5/5 і високий ризик тупика — якщо frame-driven злипання виглядає «гумово», в цих API немає плану Б.

### Варіант C: @expo/ui/swift-ui — майже, але ні ❌

Цікавий звір: дає справжні SwiftUI-примітиви (`GlassEffectContainer`, `Namespace`, `glassEffectId`) прямо з JS. Але: бета, максимум 3 статичні namespace (динамічні — «hacky», це слова самих авторів PR), задокументовані production-регресії хостинг-шару (прозорий перший кадр, мертві тачі в модалках), і воно тягне бета-пакет у bare-проєкт — погано для порта в Numo.

### Варіант D: свій SwiftUI-компонент, вбудований у RN — так ✅

Морф-fidelity 5/5, бо це буквально ті самі API, якими Apple робить свої морфи. Спрінги, шимер, стретч на дотик — нативні, без бридж-латентності. А тюнінг параметрів з JS зберігається через пропси.

Єдине «але» на старті: публічних прикладів «RN-driven glassEffectID tab bar» не існувало — ми були перші. Прототип цей ризик зняв: усе працює.

---

## 2. Як влаштовано: три поверхи

```
┌─────────────────────────────── React Native ───────────────────────────────┐
│ екрани / навігація контенту / бізнес-стейт / дебаг-панель / персист конфігу │
│        tabState reducer (seq/lastSeq)          config (JSON-об'єкт)         │
└───────────────┬───────────────────────────────────────────▲────────────────┘
        events ↑│ onTabPress / onSubTabPress / onExpandChange│↓ props
                │  {tab, seq}                                │ expanded, activeTab,
                │                                            │ lastSeq, config
┌───────────────▼────────────────────────────────────────────┴────────────────┐
│                     Міст (у прототипі: Expo Modules)                         │
│  GlassTabBarModule.swift → View(GlassTabBarExpoView.self)                    │
│  GlassTabBarExpoView: ExpoSwiftUI.View + ExpoSwiftUI.WithHostingView         │
│  props: @Field expanded/activeTab/lastSeq/config(Record) + EventDispatcher×3 │
└───────────────┬──────────────────────────────────────────────────────────────┘
                │ чисті Swift-типи (Config struct + closures)
┌───────────────▼──────────────────────────────────────────────────────────────┐
│              SwiftUI-ядро (wrapper-agnostic, НУЛЬ expo-імпортів)              │
│  Core/GlassTabBarView.swift   — морф, стани, анімації, пін appearance         │
│  Core/GlassTabBarConfig.swift — plain struct усіх тюнабельних параметрів      │
└──────────────────────────────────────────────────────────────────────────────┘
```

Головний принцип: **`Core/` не знає ні про Expo, ні про RN.** Це просто SwiftUI-в'юха з Config-структурою і колбеками. Обгортка (зараз Expo Modules, у Numo може бути чистий Fabric) — замінна деталь.

---

## 3. Морф: як зроблено і на чому він тримається

```
GlassEffectContainer(spacing: config.containerSpacing)   // ОДИН контейнер на обидва стани
└─ HStack
   ├─ HomePill
   │    контент (хайлайт + іконка) ← ВСЕРЕДИНІ glass-в'юхи, це важливо
   │    .glassEffect(..., in: Capsule())
   │    .glassEffectID("home", in: glassNS)       // id стабільний в обох станах
   ├─ if !expanded:
   │    PlusButton  .glassEffectID("plus")  .glassEffectTransition(.matchedGeometry)
   │    RightPill   .glassEffectID("bubble", in: glassNS)    // ← джерело морфа
   └─ else:
        ExpandedBubble .glassEffectID("bubble", in: glassNS) // ← ціль морфа (ТОЙ САМИЙ id)
        └─ 3 × SubTab; активний хайлайт = Capsule().fill(...)
             .matchedGeometryEffect(id:"highlight", in: highlightNS)  // ковзає, не кросфейдить
```

Правила, за порушення яких платиш флікером або кросфейдом замість морфа:

1. Обидві гілки стану живуть в **одному** `GlassEffectContainer`.
2. Порядок модифікаторів: layout → `glassEffect` → `glassEffectID`.
3. id `"home"` і `"bubble"` ніколи не змінюються між станами; тільки `"plus"` входить/виходить.
4. Всі переходи — `withAnimation(.spring(duration:bounce:))`. Рідні спрінги, 120Hz з коробки.
5. Ніколи не анімувати opacity на гласі чи його предках (та сама міна, що і в RN-лібках — це обмеження iOS).

### Урок, оплачений кров'ю: контент мусить жити ВСЕРЕДИНІ скла

Ми один раз винесли контент (іконки + хайлайт) окремим шаром **над** контейнером — хотіли захистити кольори від vibrancy (глас трохи підфарбовує свій контент під фон). Кольори стали ідеальні. А ще стало мертве все живе:

- прес перестав тягнути кнопку (interactive-стретч розтягує glass-в'юху разом з її контентом — а контент був уже не її);
- морф втратив «липкість з блюром» — бо блюрить/рефрактить система саме контент всередині скла;
- і сюрприз: контейнер малює об'єднаний скляний шар **поверх** усього не-скляного всередині себе — іконки почали рефрактитись, як за матовим склом.

Другий підхід — молочний шар-капсула поверх скла — сховав крайову рефракцію і шимер. Теж відкат.

**Фінальна формула:** контент всередині glass-в'юхи (як у Apple), «молочність» — не окремим шаром, а **тінтом у самому матеріалі**: `Glass.regular.tint(.white.opacity(milk))`. Тоді краї, стретч, шимер і морф-блюр живі, а білий тінт ще й глушить vibrancy-шифт кольорів. Це чесний трейдофф: ідеально стабільні кольори і живі анімації одночасно не даються — анімації важливіші.

І ще: `containerSpacing` — це і є «липкість» злипання. Поставиш 0 — gooey-ефект вимкнеться. Наш дефолт: 24.

---

## 4. Стейт: оптимістичний натив + seq/lastSeq

Проблема: якщо чекати роундтрип «тап → JS → проп → анімація», морф стартує із затримкою, а controlled-пропси з RN можуть «побити» вже запущену анімацію.

Рішення — натив головний, RN наздоганяє:

1. Натив морфить **негайно** по тапу (внутрішній `@State`), інкрементує лічильник `seq` і шле подію вгору: `onTabPress {tab, seq}`, `onExpandChange {expanded, seq}`.
2. RN-reducer оновлює стейт (перемикає екран) і ехоїть `lastSeq` назад пропсом.
3. Натив застосовує controlled-пропси тільки якщо `props.lastSeq >= localSeq` **і** значення реально відрізняється.

Наслідки: нормальний потік — no-op (без подвійної анімації); застаріле ехо при швидких тапах ігнорується; імперативний контроль з RN (deep link, панель) працює, бо після спокою `lastSeq == localSeq` і відмінне значення перемагає. `config` застосовується завжди, без гейтів.

---

## 5. Конфіг матеріалу

Всі тюнабельні параметри їдуть одним об'єктом: TS-тип (`src/debug/configSchema.ts`, там же дефолти і мапа тем) → Expo `Record` (`GlassConfigRecord`) → plain `GlassTabBarConfig` struct. Поле-в-поле дзеркало, конвертація в одному місці (`toConfig()`).

Зміна будь-якого поля з JS ре-рендерить SwiftUI без ремаунта — тому дебаг-панель тюнить матеріал наживо. Зараз там: молочність (`milkOpacity`, тінт у матеріалі), тема (accent/light/mid з палет Numo), appearance (light/dark), липкість (`containerSpacing`), спрінги (duration/bounce), скрім. Точний актуальний список полів — **дивись `GlassTabBarConfig.swift`, код — джерело правди** (список мінявся кожну ітерацію панелі, док за ним не бігає).

Окрема міна, яку ми вже знешкодили: light/dark для гласа **не** перемикається через SwiftUI `.environment(\.colorScheme)` — глас читає UIKit `traitCollection` хостячої в'юхи. Робочий фікс зашитий у Core: невидимий `UIViewRepresentable` знаходить HostingView по superview-ланцюгу і ставить `overrideUserInterfaceStyle`, а `.id("scheme-…")` пересоздає глас (без цього ефект не пере-рендериться після зміни трейта).

---

## 6. Хостинг у прототипі (Expo Modules у bare RN)

- `npx install-expo-modules` офіційно підтримує bare RN; локальний модуль у `./modules` автолінкується (`use_expo_modules!` у Podfile).
- SwiftUI-в'юха для standalone-маунта у Fabric мусить конформити `ExpoSwiftUI.WithHostingView` — інакше червоний dev-екран «SwiftUI view mounted inside a standard UIView».
- Події: `EventDispatcher`-проперті у ViewProps вайряться автоматично (reflection).
- Сайзинг: RN-стиль авторитетний — даємо контейнеру явну висоту (62pt бар + headroom під шимер), SwiftUI вирівнюється по низу.

---

## 7. Порт у Numo

Два шляхи, обидва **не чіпають `Core/`**:

1. **Через expo-modules-core** (install-expo-modules на bare-проєкт) — найдешевше, модуль з прототипу майже copy-paste.
2. **Чистий Fabric-компонент**: codegen-спека + `RCTViewComponentView`, всередині `UIHostingController(rootView: GlassTabBarView(...))`, пропси мапляться в Config, події — через Fabric event emitter. Більше бойлерплейту, нуль нових залежностей. Референси: RN WG «Fabric Native Components» + Callstack «Exposing SwiftUI Views to React Native».

Вимоги в обох випадках: RN 0.80+ (New Architecture), Xcode 26+, iOS 26 SDK. Якщо min target Numo < 26 — гейтити рантаймом (`if #available(iOS 26, *)`) і мати фолбек-бар (звичайний blur/solid) для старіших iOS.

---

## 8. Граблі, які вже зібрані (не наступати повторно)

| Грабля | Симптом | Фікс |
|---|---|---|
| Контент бара поза glass-в'юхою | Зникають стретч на дотик, морф-блюр, липкість; іконки рефрактяться контейнером | Контент — всередині glass-в'юхи; «молоко» — тінтом у матеріалі, не шаром (див. §3) |
| `containerSpacing = 0` | Морф є, але «липкість» злипання зникла | Це і є параметр gooey; тримати > 0 (наш дефолт 24) |
| expo-modules-core 57 на Swift 6.2 (Xcode 26.3+) | `sending 'emitter' risks causing data races` в EventEmitter.swift | У Podfile post_install: `SWIFT_VERSION = 5.0` для таргета ExpoModulesCore; свій podspec теж `swift_version = '5.0'` |
| Prebuilt RN core (0.86) + сторонній codegen | Лінкер: `typeinfo for facebook::react::Props… symbol(s) not found` після додавання нативних лібок | У Podfile: `ENV['RCT_USE_RN_DEP']='0'`, `ENV['RCT_USE_PREBUILT_RNCORE']='0'` (збірка core з сирців) |
| SwiftUI-в'юха без хостинг-обгортки | Червоний екран «mounted inside a standard UIView… wrap with `<Host>`» | Конформити `ExpoSwiftUI.WithHostingView` — core сам загорне, `@expo/ui` не потрібен |
| `.environment(\.colorScheme)` на глас | Dark mode «не працює» | `overrideUserInterfaceStyle` на HostingView + `.id()` для пересоздання гласа (див. §5) |
| Пробіл у шляху проєкту | Падають CP-User script phases (`bash: /Users/…/Empty: No such file`) | Тримати проєкт на шляху без пробілів; після переносу чистити `node_modules/**/.DerivedData` |
| Системний ruby 2.6 | CocoaPods/Expo-скрипти сипляться (`filter_map`, Unicode) | `LANG=en_US.UTF-8 /opt/homebrew/bin/pod install`, не `bundle exec` |
| opacity на glass-елементах | Глас назавжди перестає рендеритись | Тільки transform/вбудовані переходи; фейди — через `glassEffectTransition` |
| DDI mount fail на девайсі | `ddiServicesAvailable: false`, «developer disk image could not be mounted» | Найчастіше телефон просто заблокований; розблокувати і повторити |
| Debug-збірка: «No script URL provided» | Червоний екран на старті | Це Metro, не бар. Feel-check робити тільки в Release (JS вшитий, 120Hz чесний) |
| Видалив Swift-файл з модуля | `Build input file cannot be found` | Перезапустити pod install (файл-ліст генерується там) |

---

## 9. Етап 2: тулбари з того ж скла

Далі поверх бара заїхав верхній тулбар — 8 конфігурацій з дев-спеки Figma (нода 278:2416): аватар, back + тайтл + сабтайтл, translate, settings + close, група Aa | ⋯, прогрес, CTA-пігулка. Питання було одне: чи треба під нього другий нативний модуль?

Не треба. Виявилось, один expo-модуль спокійно тримає кілька в'юх: `ModuleDefinition.views` — це словник, перша `View()` в дефініції лишається дефолтною (старий `GlassTabBarView` нічого не помітив), а кожна наступна експортується під ім'ям свого Swift-класа. З JS це просто `requireNativeView('GlassTabBar', 'GlassToolbarExpoView')` з пакета `expo`.

Саме ядро (`Core/GlassToolbarView.swift`) — той самий рецепт, що і бар, без винятків: контент усередині glass-в'юхи, молоко тінтом у матеріалі, той самий `GlassTabBarConfig` (тобто слайдери панелі крутять бар і тулбар синхронно). Головний трюк — стабільні `glassEffectID` по слотах: лівий елемент завжди `"tb-lead"`, правий — `"tb-trail"`. Перемикаєш конфігурацію в панелі — і аватар морфиться у translate-кнопку, група Aa | ⋯ перетікає в CTA, бо для системи це «той самий» шматок скла, що змінив форму. `option` приходить пропом і анімується локальним стейтом через `withAnimation(config.spring)` — так само, як бар анімує свої стани.

Тайтл, сабтайтл і прогрес скла не мають — вони лежать на підкладці, як нативні заголовки нав-барів, а читабельність їм забезпечує верхній scroll edge effect. Тулбар живе прямо всередині верхнього `ScrollEdgeEffect`-контейнера — кишеня блюру формується навколо реального скла, без жодних невидимих шейперів (урок §7 діє). CTA-пігулка — як «+» у барі: суцільний акцентний філ у glass-контенті + `tint(accent)`, рим дає саме скло замість фейкового inner glow з макета.

Дрібниці: шрифту Obviously в проєкті нема, тайтл тимчасово рендериться SF-ом через `.fontWidth(.condensed)` bold — на око близько до Narrow Bold, файл шрифта можна підкинути пізніше. Кнопка settings (конфігурація 5) відкриває дев-панель, back згортає розгорнутий бар. І ще одна грабля симулятора в копилку: `simctl openurl` на кастомну схему показує confirm-діалог — тому скриптовані прогони станів робляться DEV_AUTOPLAY-циклом, не діп-лінками.

---

## 10. Етап 3: прощання з Expo — модуль на голому Fabric

Фінальний крок перед портом у Numo: викинути expo-modules-core з мосту. Ядро (`Core/*.swift`) не змінилось ні на символ — мінявся тільки шар між RN і SwiftUI.

Що тепер замість Expo: `package.json` модуля з `codegenConfig` (спека GlassBarSpec, `ios.componentProvider` мапить імена компонентів на класи) + дві TS-спеки `*NativeComponent.ts` (пропси включно з вкладеним config-обʼєктом, події через `DirectEventHandler` з seq) + ObjC++ шелли `*ComponentView.mm` (Fabric-дескриптор, каст C++ пропсів, event emitter) + @objc Swift-мости `*HostView.swift` з `UIHostingController` всередині. Реєструється все само на `pod install`: codegen генерить C++ і запис у `RCTThirdPartyComponentsProvider`, автолінк подає подспек. В апці — один запис у `react-native.config.js`. Порт у Numo: скопіювати папку модуля, додати цей запис, pod install. Все.

Дві граблі, які коштували по ітерації збірки. Перша: RN CLI шукає подспек **тільки в корені пакета** — Expo тримає його в `ios/`, і з цієї звички залежність мовчки зникає з автолінку (CLI ковтає помилку без жодного варнінгу). Друга: под, де живуть і Swift, і ObjC++, з `DEFINES_MODULE` пробує зібрати clang-модуль з усіх публічних хедерів — а хедери ComponentView тягнуть C++-заражені Fabric-хедери, і Swift-половина падає з «'atomic' file not found». Лік: `private_header_files` на всі свої хедери — в umbrella їм нічого робити.

І головне архітектурне: SwiftUI-дерево живе в **одному** UIHostingController, а пропси заходять мутаціями ObservableObject-стейту. Перестворювати rootView на кожен апдейт не можна — злетять @State, @Namespace і разом з ними всі морфи. Плюс `safeAreaRegions = []` на хостинг-контролері: бар і тулбар — оверлеї, їм чужі safe-area інсети ні до чого. Пін дарк-мода з §5 пережив переїзд безкоштовно — в'юха UIHostingController називається `_UIHostingView`, і наш пошук по «HostingView» знаходить її так само, як знаходив Expo-шну.

---

## 11. Етап 4: чому «вищий» edge не блюрив, і де насправді живе регіон блюру

Симптом з девайса: зона тулбара перекриває контент якимось wash-ем, але не розмиває його. Розкопки хедерів iOS 26.2 SDK дали чітку картину, яку варто запам'ятати назавжди:

**Блюр-смуга `UIScrollEdgeEffect` йде за safe area скрола, а не за content inset.** Мій перший підхід — віддати висоту тулбара в `contentInset` — посунув контент, але блюр як був заввишки зі статус-бар, так і лишився. А `UIScrollEdgeElementContainerInteraction` (кишені навколо оверлеїв) сам блюру НЕ додає — він, цитуючи хедер, лише «affects the SHAPE of the edge effect»: формує вже наявний ефект навколо елементів. Формуєш згаслий ефект — отримуєш wash без розмиття. Публічної ручки розміру регіону не існує взагалі: у ефекту два поля, `style` і `hidden`, крапка.

Єдиний легальний шлях зробити блюр вищим — **виростити safe area**: `UIViewController.additionalSafeAreaInsets`. Саме так живуть справжні нав-бари (плюс власний бекграунд-блюр у tall-станах), і SwiftUI-шний `safeAreaBar` — той самий патерн під іншим соусом.

Тому тулбар-компонент отримав проп `edgeExtension`: нативно (через responder chain до root VC) виставляє `additionalSafeAreaInsets.top`. Два зайці одним пострілом: справжній progressive blur розтягується на всю зону тулбара, і `contentInsetAdjustmentBehavior="automatic"` сам відсуває контент з коректною компенсацією оффсету — костилі `contentInset`/`contentOffset` з DemoScreen виїхали повністю. При анмаунті тулбара (опція Off) інсети повертаються до нуля в `didMoveToWindow`.

Нюанс на RN-боці: safe-area-context тепер повертає insets.top уже З розширенням — тулбар позиціонується від `insets.top - edgeExtension`, інакше з'їде вниз на власну ж прибавку.

У панелі це «Toolbar edge height» (44–160) у секції «Край скролу». Матеріал заодно зафіксували: milk 0.95 як дефолт, контролі матеріалу з панелі прибрані.

---

## 12. Етап 5: здаємо системний edge, забираємо блюр собі

Чесний підсумок трьох раундів із `UIScrollEdgeEffect`: у RN-обв'язці він некерований. Смуга ефекту прив'язана до safe area, interaction-кишені лише формують її навколо елементів, публічних ручок розміру нема — і навіть виростивши safe area через `additionalSafeAreaInsets`, видимого блюру на девайсі ми не отримали. Скільки не годуй систему правильними інсетами — малює вона сама, де хоче.

Тому ресет: bsky-ліба і весь inset-цирк видалені, а блюр тепер наш власний. Третій компонент модуля — **GlassEdge**: SwiftUI `Material` (.ultraThinMaterial) під маскою з градієнта з ease-стопами. Прийом старий як світ (так progressive blur роблять 90% апок, бо справжній variable blur Apple тримає в приватному CAFilter), повністю легальний і — головне — повністю наш: висота задається з RN, крива — в одному місці в коді, dark підхоплюється матеріалом сам.

Бонус, який важко переоцінити: Material рендериться на симуляторі. Вперше за весь проєкт край скролу можна ітерувати скріншотами, без збірки на телефон.

У лейауті два стрипи з `pointerEvents="none"`: верхній (`insets.top + слайдер`, дефолт 80) під тулбаром, нижній (`insets.bottom + 96`) під баром. Тогл «Native edge blur» у панелі тепер вмикає/вимикає саме їх, а слайдер «Top blur height» тягне верхній хоч до 220. Контент відступає від тулбара простим паддінгом — після всіх пригод з інсетами це найчесніше рішення.

---

## 13. Епілог країв: назад до scrim — і чому це правильно

Сага країв зробила повне коло: системний edge effect (некерований) → власний Material з маскою (не блюрить — маска гасить прозорість, не радіус) → приватний variableBlur (справжній блюр, і голий, і в композиті з фростом). І фінальний твіст: композит зіпсував головне — **скло вкладок бара**. Бекдроп-шар під glass-компонентом стає частиною того, що семплить його скло: пігулки бара почали дивитись на білий фрост замість контенту і «вигоріли».

Це головний урок усієї саги: **під Liquid Glass не можна підкладати інші бекдроп-ефекти.** Скло має семплити контент.

Фінал (за рішенням дизайнера): краї — це просто **scrim-градієнт з макета** (Figma 320:2512), реалізований на RN-боці через expo-linear-gradient: 16 eased-стопів, білий від 0.9 на краю до нуля, топ 356pt, низ 114pt, у дарку та сама крива на #121316. Плоский градієнт не є бекдроп-ефектом — скло пігулок бачить крізь нього контент, як і задумано. Весь нативний GlassEdge/variableBlur-стек видалений з модуля; модуль знову складається рівно з двох компонентів — бар і тулбар. Іноді найкраща інженерія — це git rm.

---

## 14. Першоджерела

- SwiftUI: `glassEffect(_:in:)`, `GlassEffectContainer`, `glassEffectID(_:in:)`, `glassEffectTransition`, `glassEffectUnion` — developer.apple.com/documentation/swiftui
- UIKit: `UIGlassEffect` (лише `init(style:)`/`isInteractive`/`tintColor`), `UIGlassContainerEffect` (лише `spacing`), `UISearchTab`, `UITabAccessory`, `tabBarMinimizeBehavior` — developer.apple.com/documentation/uikit
- github.com/callstack/liquid-glass — README + issues #27, #33, #41, #42
- expo-glass-effect docs + expo/expo issues #41024, #41025; @expo/ui glass PR: expo/expo#39070
- react-navigation native bottom tabs / Expo NativeTabs — задокументовані обмеження кастомізації
- Expo Modules: docs.expo.dev/modules (bare install, autolinking), сорси ExpoSwiftUI в expo-modules-core
- Fabric + SwiftUI: react-native-new-architecture/docs/fabric-native-components.md, Callstack «Exposing SwiftUI Views to React Native»
- Тон-адаптація гласа (чому кольори «пливуть» і чому це by design): WWDC25 session 219 «Meet Liquid Glass», Apple DTS у forums thread 814005

---

## TL;DR для дева

100% нативний Liquid Glass морф у чистому RN недосяжний за дизайном платформи — matched-geometry морф Apple віддала тільки SwiftUI. Робоча форма (перевірена прототипом на девайсі): тонкий нативний SwiftUI-компонент бара з оптимістичним стейтом і seq-реконсиляцією, решта застосунку — RN. Контент живе всередині скла (інакше вмирають стретч і морф-блюр), молочність — тінтом у матеріалі, spacing > 0. Ядро wrapper-agnostic — у Numo заїжджає через expo-modules-core або чистий Fabric без переписування.
