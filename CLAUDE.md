# Elapsed Time Adder — Claude Context

## Proactive memory
Update this file at the end of every session or whenever a meaningful decision is made, so context is preserved across machines and sessions.

---

## Project goal
Build a native iOS + macOS app called **Elapsed Time Adder** using SwiftUI (single multiplatform Xcode project). The owner (Allison) has no prior Swift experience — Claude Code is writing the Swift. 

The original web app (HTML/CSS/JS/jQuery/Bootstrap) lives in `web/` for reference. Do not modify it.

---

## About the user
- Allison (@podfeet.com), podcaster, comfortable with web tech but new to Swift and Apple app development
- Prefers Claude Code to write the Swift code; Allison reviews and directs

---

## Key decisions made
- **SwiftUI multiplatform** (not WKWebView wrapper) — native app, single codebase for iOS + macOS
- **Single +/− toggle button per row** (not per field) — the whole row is positive or negative — implemented as a segmented Picker showing `+` / `−`
- **H/M/S fields accept positive numbers and decimals only** — no negative input in fields
- **Math logic ported from** `web/src/timeMath.js` — algorithm must be preserved exactly (see REQUIREMENTS.md)
- **No persistence in v1** — state resets on relaunch
- **No row deletion or reordering in v1**
- **Column headers** use `Hrs / Min / Sec` (not single letters H/M/S)
- **Total lives above the rows** — placing it below caused the keyboard to cover it on iPhone; keyboard toolbar approach was tried and abandoned (SwiftUI `.keyboard` toolbar placement caused tap-blocking bugs)

---

## Current status
- Xcode project fully built and working — all core features implemented
- All tests passing (unit + UI/accessibility) when run on an **iPhone simulator** destination
- Project renamed from `ElapsedTimeAdder` → `ElapsedTimeAdder` (folder, scheme, targets)
- Wide (iPad/Mac) layout uses `NavigationSplitView` — fixes blank white left column that appeared with `NavigationStack` + `WindowGroup`
- **In-app name is always "Elapsed Time Adder"** — never "Calculator." Home screen display name is **"Time Adder"** (set via `INFOPLIST_KEY_CFBundleDisplayName` in `project.pbxproj`); App Store Connect listing name is set separately there as "Elapsed Time Calculator" (that is the only place "Calculator" is acceptable)
- DocC documentation added for non-UI code (`TimeMath.swift`, `ExportHelpers.swift`, `TimeRow.swift`) — catalog at `ElapsedTimeAdder.docc/`. Build with **Product → Build Documentation** in Xcode.
- App icon updated — source at `assets/ElapsedTimeAdderIcon.png` (1024×1024); all required sizes generated via `sips` into `Assets.xcassets/AppIcon.appiconset/`

---

## Xcode project layout
```
ElapsedTimeAdder/                     Xcode project root
  ElapsedTimeAdder.xcodeproj/
    xcshareddata/xcschemes/
      ElapsedTimeAdder.xcscheme
  ElapsedTimeAdder/                   app source
    ElapsedTimeAdderApp.swift
    ContentView.swift
    TimeRow.swift                          @Observable model
    TimeRowView.swift                      single row UI + validation
    TimeMath.swift                         port of web/src/timeMath.js
    ExportHelpers.swift                    CSV + HH:MM:SS export
    Assets.xcassets/                       app icon + PodfeetLogo
  ElapsedTimeAdderTests/              unit tests
    TimeMathTests.swift
    ValidationTests.swift
    ExportTests.swift
  ElapsedTimeAdderUITests/            UI + accessibility tests
    AccessibilityTests.swift
web/          original web app (reference only, do not modify)
REQUIREMENTS.md  full feature spec for the Swift app
CLAUDE.md        this file
```

## iPhone layout: List instead of ScrollView

SwiftUI's `ScrollView` on iOS delays touch delivery to child views while deciding if a gesture is a scroll — causes text fields to require multiple taps to focus. **Fix: use `List` with `.listStyle(.plain)` and `.scrollContentBackground(.hidden)` for the narrow layout.** `List` is backed by `UITableView` which handles the scroll/tap distinction correctly.

- Each list row uses a `plainRow(top:bottom:)` helper (private extension on `View`) that applies `.listRowSeparator(.hidden)`, `.listRowBackground(Color.clear)`, and `listRowInsets(leading: 16, trailing: 16)`
- `columnHeaders` needs `.padding(.horizontal, 10)` before `.plainRow()` to match `TimeRowView`'s internal `.padding(10)` — without it the Hrs/Min/Sec headers are right-justified against the field edges instead of centered above them
- `UIScrollView.appearance().delaysContentTouches = false` breaks ALL of SwiftUI's gesture handling — never use it
- A targeted `UIViewRepresentable` walk-up-the-hierarchy approach also failed inconsistently across devices (iPhone 17 Pro vs 15 Pro)

---

## UX improvements (intuitive-interface branch)

Four changes made to improve discoverability for new users:

1. **+/− segmented picker** (`TimeRowView.swift`) — replaced single toggle button with a `Picker(.segmented)` showing `+` and `−`. Both options always visible so users see it's a choice, not just a button. Tinted green (add) or red (subtract).

2. **Color-coded row backgrounds** (`TimeRowView.swift`) — each row has a faint green or red background matching the picker state. The background and picker tint update together when toggled.

3. **Expanded column headers** (`ContentView.swift`) — `H / M / S` → `Hrs / Min / Sec`.

4. **Persistent usage hint + spreadsheet button** (`ContentView.swift`) — replaced the hidden "How it works" toggle with:
   - Always-visible two-liner under the title (centered), with hardcoded `\n` breaks: *"Enter a time in each row and\nchoose Add (+) or Subtract (−).\nThe total updates as you type."*
   - Small blue "Why not use a spreadsheet?" button at the bottom (collapsible, footnote size)

5. **Plain-English total** (`ContentView.swift`) — both iPhone and iPad/Mac show a `.title2.bold()` summary line (e.g. *"1 hr 23 min 45 sec"*) below the rows. The H/M/S total boxes (`totalSection`, `totalBox`) have been deleted. Export buttons moved to below "Add Another Row" on iPhone.

6. **Tab-to-add-row** (`TimeRowView.swift`) — pressing Tab from the last row's seconds field adds a new row. Implemented via `TabToAddRowModifier` (private `ViewModifier`) applied only to the last row using `isLast` + `onAddRow` params passed from ContentView's ForEach. Error message updated to "Positive numbers, you silly goose!"

7. **WCAG AA contrast fixes** (`ContentView.swift`) — all tinted buttons (Add Another Row, Export CSV, Export HH:MM:SS, Reset) changed from colored text on tinted background to `.primary` text; usage hint, spreadsheet button label, and "A Podfeet App" branding changed from `.secondary` to `.primary`. Background tints remain as color cues. Spreadsheet note text changed from `.secondary` to `.primary`.

**Row layout** (both narrow and wide): title field on line 1 full-width; H/M/S fields + +/− picker share line 2. On iOS the title placeholder is just "title"; on macOS/iPadOS it says "title (opt)".

**Wide layout (iPad/Mac):**
- Uses `NavigationSplitView` with `.balanced` style — sidebar left, detail right
- Sidebar column width set to `640pt` via `.navigationSplitViewColumnWidth(min: 320, ideal: 640, max: 640)`
- Sidebar holds: title, usage hint, export buttons (stacked, 320pt wide / 50% of sidebar), spreadsheet button, branding
- Detail column holds: column headers, rows, total summary, Add Another Row, Reset
- Detail column content capped at 560pt wide so rows don't stretch absurdly
- Add Another Row and Reset buttons capped at 320pt, centered
- Starts with 5 rows on wide layouts (via `.onAppear`), 2 on iPhone
- Sidebar background: `Color.secondary.opacity(0.12)` with `.ignoresSafeArea(edges: .leading)`
- `.prominentDetail` style hides the sidebar — don't use it; use `.balanced`

**Things that didn't work / were reverted:**
- Keyboard toolbar showing total above the numeric keypad — `Spacer()` inside `ToolbarItemGroup(placement: .keyboard)` creates an invisible tap-blocking overlay; splitting into separate `ToolbarItem` entries also caused severe input issues. Abandoned entirely.
- Total below the rows — keyboard covers it on iPhone

---

## Key gotchas discovered
- **Always run tests on an iPhone simulator** — running on "My Mac" destination causes all UI/accessibility tests to report 0 elements found (macOS accessibility tree is different)
- **Parallel UI tests**: scheme has `parallelizable = YES` so Xcode spawns 3 simulator clones; each clone shows the app + a no-icon test runner process — both are normal
- **project.pbxproj uses `PBXFileSystemSynchronizedRootGroup`** — no need to manually register new `.swift` files; Xcode auto-includes everything in the target folders
- **After the project rename**, `TEST_TARGET_NAME` in the UITests build config was still set to `ElapsedTimeAdder`, causing UI tests to silently not run — fixed by updating all stale name references in `project.pbxproj` via `sed`
- **SwiftUI keyboard toolbar** (`placement: .keyboard`) is very buggy — `Spacer()` inside `ToolbarItemGroup` creates an invisible overlay that blocks taps on content below; don't use it
- **Negative padding** (e.g. `.padding(.bottom, -10)`) moves views visually but leaves the original layout frame in place, causing invisible hit-area overlap that blocks taps — never use it
- **`UIScrollView.appearance().delaysContentTouches = false`** breaks ALL SwiftUI gesture handling app-wide — never use it
- **iPhone narrow layout uses `List` not `ScrollView`** — see "iPhone layout" section above for details and the `columnHeaders` alignment fix
- **Worktree vs main project**: Claude Code runs in a git worktree (`.claude/worktrees/…`) but Xcode opens the main project directory — always edit files in `/Users/allison/htdocs/elapsed-time-calculator/ElapsedTimeAdder/` not the worktree path
- **Wide layout safe area**: use `.ignoresSafeArea(edges: .leading)` on the sidebar `ScrollView` inside `NavigationSplitView` to make the sidebar background reach the left screen edge on iPad
- **`NavigationSplitView` blank column**: `WindowGroup` on iPad creates a `UISplitViewController` primary column regardless of `NavigationStack` — only `NavigationSplitView` gives you explicit control over both columns. Use it for any wide layout with a sidebar.
- **`.prominentDetail` hides the sidebar** — use `.balanced` to keep both columns visible
- **`onKeyPress` on multiple TextFields inside `List` breaks touch delivery** — even returning `.ignored` is enough to disrupt `UITableView`'s touch handling. Fix: use a `ViewModifier` that conditionally applies `onKeyPress` only when needed (e.g. `isLast`), so non-target rows get zero modification. See `TabToAddRowModifier` in `TimeRowView.swift`.
- **UI tests must run on iPhone simulator** — Mac and iPad destinations produce wrong accessibility trees; always use iPhone simulator for `AccessibilityTests`
- **Decimal pad prevents typing letters in UI tests** — `typeText("abc")` fails on fields with `.keyboardType(.decimalPad)`; use `typeText("1..")` instead (double decimal is invalid per `isValidTimeInput` and typeable on decimal pad)
- **Segmented Picker is `segmentedControls` in XCTest**, not `buttons` — use `app.segmentedControls.matching(identifier:)` and check individual segment selection with `.buttons["+"].isSelected`
- **List uses `app.swipeUp()` not `app.scrollViews`** — the narrow layout's `List` is a `UITableView`; swiping on the app directly is the most reliable approach
- **WebKit axbundle duplicate warning** in test output is a simulator runtime issue, not an app bug — ignore it
- **Free Apple Developer account certificates expire every 7 days** — when this happens, go to Xcode → Settings → Accounts → Manage Certificates, delete the expired certificate, create a new Apple Development one, then clean build (Cmd+Shift+K) and rebuild. Paid account ($99/year) required for TestFlight and App Store.
- **Icon sizes**: `@2x` variants must be double the logical pixel size (e.g. `512@2x` = 1024px, `256@2x` = 512px, `128@2x` = 256px). Use `sips -z <h> <w> source --out dest` to generate. Source file lives at `assets/ElapsedTimeAdderIcon.png`.
- **WCAG AA contrast**: `.secondary` foreground color (~2.85:1 on white) fails AA; `.blue` text on `.blue.opacity(0.12)` background (~2.5:1) also fails. Use `.primary` text with tinted backgrounds for color coding instead.
- **TestFlight external distribution**: when archiving in Xcode, choose **App Store** (not TestFlight) in the Distribute flow. Choosing TestFlight-only skips Beta App Review, which means external tester groups can never be added to the build — it stays internal-only forever.
- **Share sheet export (iOS)**: uses `UIActivityItemSource` (`ExportActivityItem` in `ExportHelpers.swift`) to route AirDrop/Files to a named file URL and Mail/Notes/Messages to inline plain text. `NSAttributedString` was tried to fix Mail's Helvetica 9 plain-text rendering but caused Mail to treat the content as an attachment — reverted. The Helvetica 9 issue is Mail's own plain-text rendering and cannot be fixed from the sender side without causing attachment behavior.
- **Share sheet app icon — REGRESSION-PRONE, has broken 4+ times**: iOS icon is set via `metadata.iconProvider = NSItemProvider(object: UIImage(named: "AppIcon"))` in `activityViewControllerLinkMetadata` inside `ExportActivityItem` in `ExportHelpers.swift`. Do NOT use `metadata.url` on iOS (it suppresses the HH:MM:SS title). macOS does NOT set a custom icon — every approach tried (NSApp.applicationIconImage, Image("AppIcon"), NSImage(named:)) either shows a broken white square or nothing. macOS uses the system file-type icon (CSV/TXT) which looks fine. Do not attempt to fix the macOS icon again without a working solution in hand.
- **CSV spaces after commas**: do not add spaces after commas in CSV output — RFC 4180 parsers treat them as part of the field value, which breaks numeric columns in spreadsheets (numbers become text strings with a leading space).
- **Export row numbering**: blank rows (empty title + all H/M/S zero) are skipped from export; remaining rows are numbered sequentially in the export (so row 3 in the app may export as "Row 2" if row 2 was blank).
- **About & Feedback sheet**: tapping the Podfeet logo + "A Podfeet App · About & Feedback" at the bottom opens `AboutSheet` with website link (timeadder.podfeet.com), email link (allison@podfeet.com, subject pre-filled), and GitHub issues link. Podfeet logo is 44pt on macOS, 28pt on iOS. On iPad/Mac the same About content is shown inline in the sidebar (`sidebarAboutContent`) instead of behind a button.
- **CSV title quoting (RFC 4180)**: title fields are always wrapped in double quotes via `csvQuote()` in `ExportHelpers.swift`, with internal `"` escaped by doubling (`""`). Without this, a comma in a title (e.g. "My Video, Part 1") shifts every following column one cell to the right in the spreadsheet. Quotes are stripped automatically by Excel/Numbers/Sheets so the user never sees them. Do NOT instead disallow commas in the title field — commas are legitimate in titles.
- **Row delete + reorder**: an "Edit Rows" button (pencil icon, tinted pill) toggles `isEditing`. iPhone uses the native List `EditMode` (`@State editMode`, wrapped in `#if os(iOS)` since `EditMode` is unavailable on macOS) with `.onDelete`/`.onMove` for minus-circles + hamburger handles; `TimeRowView` takes an `isEditMode` flag that switches it to a two-line layout (title on its own line) ONLY in edit mode, so the system edit controls don't crush the title field to one character wide. iPad/Mac wide layout uses custom controls instead: a minus-circle delete button and a `line.3.horizontal` drag handle, with reordering via `onDrag`/`onDrop` + `RowDropDelegate` (EditMode environment does NOT reliably propagate through `NavigationSplitView`'s detail column). Minimum 2 rows enforced in `deleteRows`.
- **`Array(repeating: TimeRow(), count:)` is a bug** — `TimeRow` is an `@Observable` class (reference type), so this creates N references to ONE instance (shared id → duplicate ForEach IDs → "Invalid frame dimension" warnings + all rows mutate together). Always use `(0..<n).map { _ in TimeRow() }` to get distinct instances. Reset uses 8 rows on wide, 2 on iPhone.
- **macOS NavigationSplitView sidebar will NOT bottom-pin content** — both the iPad VStack wrapper (`VStack { ScrollView; aboutContent }`) and `.safeAreaInset(edge: .bottom)` fail on macOS: the first spins the beachball (layout loop), the second overflows content past the top and bottom of the window. On macOS the About content just scrolls at the bottom of the sidebar with `.padding(.top, 48)` for separation. iPad bottom-pins fine via the VStack wrapper because UIKit's split view sizes columns differently than AppKit's.
- **Sidebar link padding differs by platform** — About & Feedback link buttons use `.padding(.horizontal, 48)` on iPad (640pt sidebar) but `16` on macOS (220–380pt sidebar); 48pt on the narrow macOS sidebar computes a negative content width during transient layout → "Invalid frame dimension (negative or non-finite)" runtime warning.
- **Dark mode color tuning**: row background tints use `colorScheme == .dark ? 0.12 : 0.08` opacity; tinted button backgrounds (`buttonOpacity`) use `0.25 : 0.12`. The wide sidebar custom background (`Color.secondary.opacity(0.12)`) is set to `Color.clear` in dark mode so it doesn't draw attention away from the detail column. The 0.08 light value is too faint on a dark background; values above ~0.15 look garishly bright.
