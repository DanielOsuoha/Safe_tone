# SafeTone

SafeTone is a SwiftUI iOS app prototype that demonstrates a call-safety UI and contains helper stubs for signaling and call handling. It combines a polished SwiftUI frontend with basic CallKit, signaling, and audio session components intended as a starting point for a full call-protection app.

## Notable features

- SwiftUI-based UI with focused screens for dialing, recents, contacts, and protection status.
- Basic CallKit and audio session helpers (`CallKitManager`, `AudioSessionManager`) and lightweight signaling models (`SignalingClient`, `CallSignalingModels`) included as starting points.
- In-call mock UI and protection states for prototyping user flows.

## Requirements

- Xcode (use the latest stable release recommended)
- iOS deployment target is set in the Xcode project; changing SDK/target may be required for older/newer toolchains

## Getting started

1. Open `SafeTone.xcodeproj` in Xcode.
2. Select a simulator or a device (some call-related features require a real device and entitlements).
3. Build and Run (⌘R).

Notes:
- The repo includes stubs and helper classes for CallKit and signaling, but running full call flows may require signing, entitlements, and backend signaling services.

## Screens and UX

- Recents — recent call list with visual verification indicators.
- Contacts — high-contrast contact list.
- Keypad / Dialer — 3×4 dial pad with a Call action that opens an in-call mock.
- Shield / Settings — protection status and controls.
- Welcome / Onboarding — two-page onboarding flow with an activation button.

## Project layout (high-level)

```
SafeTone/
├── SafeToneApp.swift
├── ContentView.swift
├── WelcomeView.swift
├── DialerScreen.swift
├── InCallScreen.swift
├── RecentsScreen.swift
├── ContactsScreen.swift
├── FavoritesScreen.swift
├── VoicemailScreen.swift
├── ShieldSettings.swift
├── DynamicTabBar.swift
├── SafeToneTheme.swift
├── ScrollOffsetPreferenceKey.swift
├── SignalingClient.swift
├── CallSignalingModels.swift
├── CallKitManager.swift
├── AudioSessionManager.swift
├── CallEngine.swift
├── CallManager.swift
├── IncomingCallHelper.swift
├── TimerManager.swift
└── Assets.xcassets/
```

## Development notes

- Some files are prototypes or scaffolding for a backend-enabled app (e.g., `SignalingClient`, `CallEngine`). Treat them as starting points rather than production-ready components.
- When testing CallKit or audio behavior on device, ensure appropriate entitlements and privacy entries in the project `Info.plist`.

## Next steps you might want

- Wire `SignalingClient` to a real signaling server for live call flows.
- Add entitlements and provisioning to test CallKit on-device.
- Replace prototype data in `RecentsScreen` and `ContactsScreen` with a real data source.

## License

Use and modify as needed for your project.
