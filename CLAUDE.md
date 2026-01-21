# Quran Memorizer - Claude Code Documentation

## Project Overview

Quran Memorizer is a native iOS app for Quran memorization (Hifz) built entirely in SwiftUI. It features A-B loop audio playback, memorization tracking at both surah and ayah levels, and beautiful reading themes.

**Developer:** Donald Cjapi (2025)
**Deployment Target:** iOS 26.0
**Architecture:** MVVM with ObservableObject state management
**External Dependencies:** None (pure native Swift)

## Quick Commands

```bash
# Open project in Xcode
open "Quran Memorizer.xcodeproj"

# Build from command line (requires Xcode)
xcodebuild -project "Quran Memorizer.xcodeproj" -scheme "Quran Memorizer" -configuration Debug -destination "generic/platform=iOS" build

# Run On-Demand Resources tagging script
ruby odr_tagging.rb
```

## Directory Structure

```
Quran Memorizer/
├── Quran_MemorizerApp.swift      # App entry point, StateObject initialization
├── ContentView.swift              # Wrapper view (can be removed, redundant)
├── Item.swift                     # UNUSED - SwiftData boilerplate, safe to delete
├── Core/
│   ├── Models.swift               # Surah, Reciter, HighlightState, HifzProgress
│   ├── Stores.swift               # AppPrefsStore, HighlightStore, MemorizedAyahStore
│   ├── StaticSurahs.swift         # All 114 surahs static data
│   └── SurahTexts.swift           # Arabic & English text for all surahs (13k lines)
├── Features/
│   ├── Surahs/
│   │   └── SurahsView.swift       # Surah list with search and progress tracking
│   ├── Memorizer/
│   │   ├── MemorizerView.swift    # Main player UI and text display
│   │   ├── MemorizerState.swift   # AVPlayer state management, A-B looping
│   │   └── ABRangeSlider.swift    # Custom A-B loop range selector
│   └── Settings/
│       └── SettingsView.swift     # Theme, reciter, and app settings
├── Shared/
│   ├── AppNav.swift               # Navigation state (selectedTab, selectedSurah)
│   └── RootTabView.swift          # Main tab bar navigation
├── Design/
│   ├── AppTheme.swift             # ThemeManager, ReadingThemes, UI components
│   └── Fonts/
│       └── KFGQPC Uthmanic Script HAFS.ttf  # Custom Arabic font
├── Quran/Resources/               # Audio files for offline playback
│   ├── Saad01/                    # Saad Al-Ghamdi (surahs 1-4)
│   └── Mishary01/                 # Mishary Rashid (surahs 1-4)
└── Assets.xcassets/               # App icons, colors, images
```

## Architecture

### State Management Pattern

```
@main Quran_MemorizerApp
    ├── @StateObject AppNav          → Navigation state
    ├── @StateObject ThemeManager    → Theme preferences (persisted)
    ├── @StateObject AppPrefsStore   → User preferences (persisted)
    ├── @StateObject HighlightStore  → Surah status tracking (persisted)
    ├── @StateObject MemorizedAyahStore → Ayah-level tracking (persisted)
    └── @StateObject MemorizerState  → Audio player state

    All injected via .environmentObject() to views
```

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| `MemorizerState` | MemorizerState.swift | AVPlayer management, A-B loop logic, playback control |
| `HighlightStore` | Stores.swift | Surah memorization status (none/inProgress/memorized) |
| `MemorizedAyahStore` | Stores.swift | Per-ayah memorization tracking |
| `ThemeManager` | AppTheme.swift | App theme and 9 reading themes |
| `Reciter` | Models.swift | Audio source URLs (local + streaming) |

### Audio System

- **Local audio:** Bundled for surahs 1-4 in `Quran/Resources/`
- **Streaming:** All 114 surahs from `download.quranicaudio.com`
- **On-Demand Resources:** Uses iOS ODR for downloadable audio packs
- **A-B Loop:** Custom implementation with timer-based or AVPlayer time observers

## Features

### Working Features
- [x] Surah list with search (by name or number)
- [x] 3-state surah highlighting (None/In Progress/Memorized)
- [x] Hifz progress tracking with visual indicators
- [x] Audio playback with 2 reciters
- [x] A-B loop playback for memorization
- [x] Playback speed control (0.5x - 2.0x)
- [x] Arabic text display with custom Uthmanic font
- [x] English translations
- [x] Per-ayah memorization tracking (double-tap)
- [x] 9 reading themes (light & dark variants)
- [x] Fullscreen reader mode
- [x] Dark/Light mode toggle
- [x] Glass background intensity control
- [x] Share app functionality

### Placeholder Features (Not Implemented)
- [ ] Sign in with Apple
- [ ] Delete account
- [ ] iCloud sync (entitlements exist but unused)

## Code Quality Issues

### Files to Clean Up

1. **`Item.swift`** - Unused SwiftData model from Xcode template. Safe to delete.

2. **`ContentView.swift`** - Only contains `RootTabView()` wrapper. Consider removing.

### Code Issues to Fix

1. **Duplicate onChange handler** in `MemorizerView.swift`:
   - Line 27-29 and Line 47-52 both handle `nav.selectedSurah` changes
   - Should consolidate into single handler

2. **Redundant condition** in `MemorizerView.swift:438`:
   ```swift
   let showEnglish = textLanguage != .arabic || textLanguage == .memorized
   // Should be: let showEnglish = textLanguage != .arabic
   ```

3. **iOS deployment target** - Set to iOS 26.0 which doesn't exist yet. Should be iOS 17.0 or 18.0.

### Potential Bugs

1. **Timer/Player sync issue** in `MemorizerState`:
   - When no player exists, `startTimer()` runs but increments time without actual audio
   - This is intentional for simulation but the logic flow is confusing

2. **Fullscreen resume logic** - `resumePlaybackAfterFullscreen` may auto-play unexpectedly

## Conventions

### Naming
- SwiftUI Views: PascalCase with `View` suffix (e.g., `MemorizerView`)
- State classes: PascalCase with descriptive suffix (e.g., `MemorizerState`, `HighlightStore`)
- Private helpers: camelCase with descriptive names

### State Management
- Use `@StateObject` at creation site (App level)
- Use `@EnvironmentObject` for injection into views
- Use `@Published` for observable properties
- Persist with `@AppStorage` (simple) or manual UserDefaults (complex)

### UI Patterns
- Use ViewBuilder for conditional views
- Use computed properties for derived state
- Animations via `.spring(duration:)` or `.easeInOut`

## Testing

Currently no unit tests or UI tests. Manual testing required:

1. **Audio playback:** Test both reciters, all available surahs
2. **A-B loop:** Test setting loop points, playback within range
3. **Memorization tracking:** Test double-tap ayah, verify surah status updates
4. **Themes:** Test all 9 reading themes in both light/dark modes
5. **Persistence:** Test that settings, progress, and memorization survive app restart

## External APIs

| Service | URL Pattern | Purpose |
|---------|-------------|---------|
| QuranicAudio | `https://download.quranicaudio.com/quran/[reciter]/[surah].mp3` | Audio streaming |

Reciters:
- `saad_al_ghamdi` - Saad Al-Ghamdi
- `mishaari_raashid_al_3afaasee` - Mishary Rashid Alafasy

## Security Notes

- No user authentication implemented
- No sensitive data collection
- Audio streamed over HTTPS
- Local storage uses UserDefaults (not encrypted)
- No network requests beyond audio streaming
