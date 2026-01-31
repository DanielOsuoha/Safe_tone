# SafeTone

A frontend-only visual prototype for a call-safety app. The UI follows Apple’s “Liquid Glass” style with a dark navy base, glass-morphic controls, and senior-friendly typography and touch targets.

## Requirements

- Xcode 26.2+ (or current Xcode with iOS 26 SDK)
- iOS 26.2+ (or adjust deployment target in the project)

## Getting Started

1. Open `SafeTone.xcodeproj` in Xcode.
2. Select an iPhone simulator (e.g. iPhone 16).
3. Press **Run** (⌘R).

No backend, CallKit, or server logic—this is a visual prototype only.

## Design

- **Base color:** Dark Navy (`#1A237E`)
- **Style:** Translucent “liquid glass” buttons, soft gradients, and high-contrast text
- **Typography:** Body text ≥ 18pt for readability
- **Touch targets:** All interactive elements are at least 60×60 pt

## Screens

| Tab / Screen | Description |
|--------------|-------------|
| **Recents** | Mock list of recent calls with verified/scam indicators. |
| **Contacts** | High-contrast contact list with large avatars and initials. |
| **Keypad** | 3×4 dial pad (0–9, *, #), number display, and emerald **Call** button with a subtle pulse. Tapping **Call** presents the live-call mockup. |
| **Shield** | Dashboard with a large **System Guard: Active** toggle and status cards (Call Verification, Scam Warnings, Block List). |
| **Live Call** (sheet) | Shown when you tap **Call** from the keypad. Large security shield; toggle between **Verified** (green) and **Scam Warning** (red). |

## Navigation

- **Tab bar:** Recents, Contacts, Keypad, Shield.
- **Dynamic behavior:** The tab bar expands (shows labels) when you tap a tab and shrinks (icon-only) when you scroll in Recents, Contacts, or Shield.

## Project Structure

```
SafeTone/
├── SafeToneApp.swift          # App entry
├── ContentView.swift          # Root: tab switching, sheet, dynamic tab bar
├── DynamicTabBar.swift        # Tab bar UI and MainTab enum
├── SafeToneTheme.swift        # Colors, fonts, glass modifier, kMinTouchTarget
├── ScrollOffsetPreferenceKey.swift  # Scroll offset for tab bar behavior
├── DialerScreen.swift         # Keypad + Call button
├── LiveCallMockup.swift       # In-call mock (Verified / Scam toggle)
├── RecentsScreen.swift        # Recents list
├── ContactsScreen.swift       # Contacts list
├── ShieldSettings.swift       # System Guard + status cards
└── Assets.xcassets/           # App icon, accent color
```

## License

Use and modify as needed for your project.
