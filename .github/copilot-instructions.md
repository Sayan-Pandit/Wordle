# Wordle Flutter Project — AI Agent Instructions

A Wordle clone built with Flutter, Firebase Auth, and Firestore. This document guides AI agents (and developers) on project structure, conventions, and setup.

## Quick Start

```bash
flutter pub get       # Install dependencies
flutter run           # Debug build
flutter test          # Run tests
flutter build android # Android release
flutter build ios     # iOS release
```

**Firebase Setup Required:** The app uses Firebase Auth (email/password + Google Sign-in) and Firestore. Ensure `lib/firebase_options.dart` is configured with your Firebase project credentials before running.

## Project Architecture

### Directory Structure

```
lib/
├── main.dart              # App bootstrap, AuthWrapper routing (splash → login → MainScreen)
├── firebase_options.dart  # Auto-generated Firebase config (DO NOT edit manually)
├── pages/                 # Main app navigation (not auth flows)
│   ├── game_page.dart     # Game modes: daily (1/day), level (unlimited), custom
│   ├── stats_page.dart    # User stats (if implemented)
│   ├── settings_page.dart # Settings
│   └── profile_page.dart  # User profile
├── screens/               # Auth flows (splash, login, register)
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   └── register_screen.dart
├── services/              # Business logic
│   ├── auth_service.dart       # Firebase Auth + Firestore user profile creation
│   └── word_service.dart       # Word retrieval (API + deterministic local fallback)
├── widgets/               # Reusable UI components
│   ├── word_grid.dart     # Game grid with colored feedback (green, orange, gray)
│   └── keyboard.dart      # Virtual keyboard
└── data/
    └── words.dart         # Local word list (fallback to API)
```

### State Management

- **Approach:** Plain `StatefulWidget` (no Redux/Riverpod/Bloc)
- **Provider:** Listed in `pubspec.yaml` but minimally used; future refactors should explore Provider for complex state
- **Game Logic:** Lives in `WordleGame` StatefulWidget—manages guess history, letter status, win/loss conditions
- **Authentication:** `AuthWrapper` uses `StreamBuilder<User?>` to route based on login state

### Key Architectural Patterns

| Aspect | Implementation |
|--------|-----------------|
| **Pages vs Screens** | Pages = main app navigation (game, stats, settings); Screens = auth flows only |
| **Error Handling** | Try-catch + `debugPrint()` for logging (no centralized error boundary) |
| **Async Safety** | Check `mounted` after Futures to prevent frame updates on disposed widgets |
| **Theming** | Dark mode hardcoded (Color 0xFF121213); Material 3 by default |
| **Word Selection** | Daily word: 1 per calendar day (deterministic); API with 3s timeout; falls back to local deterministic generation |

## Firebase Integration

### Authentication
- **Methods:** Email/password + Google Sign-in
- **Flow:** `AuthService.registerUser()` creates user in Auth + Firestore profile doc
- **Email Verification:** Optional (sent post-registration, resend available from HomePage)

### Firestore Structure
```
users/
└── {uid}/
    ├── email: string
    ├── createdAt: timestamp
    └── displayName: string (optional)
```

### Important Notes
- **Profile Creation:** Non-blocking (doesn't prevent game access if write fails)
- **Silent Failures:** DB write failures are caught but don't notify user—watch logs
- **No Game Stats Persistence:** User profiles created but game stats/history not yet stored

## Development Conventions

### Code Style
- **File Naming:** Use descriptive names (e.g., `word_grid.dart`, `keyboard.dart`)
- **Widget Organization:** Functional widgets → StatelessWidget → StatefulWidget
- **Async Patterns:** Always check `mounted` before `setState()` after await

### Game Logic Rules
- **Daily Mode:** 1 puzzle/day, same for all users (coordinated by date)
- **Level Mode:** Infinite puzzles, different word each attempt
- **Attempts:** 6 guesses per puzzle (hardcoded in `game_page.dart`)
- **Valid Moves:** Only US English words (validated against local list + API)

### Testing
- **Current State:** Minimal (only template `widget_test.dart` exists)
- **Gaps:** No unit tests for `WordService`, `AuthService`, or game logic
- **Priority:** Add tests for `isValidWord()`, `getDailyWord()`, guess validation, win/loss conditions

## Common Pitfalls & Gotchas

1. **Firestore Rules & Silent Failures**
   - Profile creation catches exceptions silently. If permissions deny writes, users play without profiles.
   - Watch `debugPrint()` logs when testing Auth flow.

2. **Email Verification Not Enforced**
   - Users can play immediately after signup (just a warning banner).
   - Design decision: accessibility over email validation.

3. **External API Dependency**
   - Daily word endpoint has 3s timeout. If API is down, app falls back to local deterministic selection.
   - Consider caching API responses to disk (not currently done).

4. **No Game Stats Persistence**
   - User profiles exist but stats (wins, streaks, guesses) not saved to Firestore yet.
   - Planning to add this will require Firestore schema updates.

5. **StatefulWidget Scaling**
   - Current approach works for current complexity. As features grow (animations, multiplayer), consider Provider or Bloc for cleaner state management.

6. **Google Sign-in Android Config**
   - Requires `google-services.json` from Firebase Console (already present in `android/app/`).
   - SHA-1 fingerprint must match project's signing certificate.

## How AI Agents Should Approach Tasks

When working on this project:

1. **Feature Implementation**
   - Game logic goes in `game_page.dart` (StatefulWidget)
   - UI components go in `widgets/` directory
   - Async services go in `services/`
   - State management: Use `setState()` for now; escalate to Provider if state becomes complex

2. **Firebase Changes**
   - Firestore writes: Use `AuthService` patterns (try-catch, mounted checks)
   - New fields: Update Firestore rules + schema documentation
   - Deploy rules via Firebase Console (not in repo)

3. **Testing**
   - Unit tests: `test/` directory
   - Widget tests: `test/` directory
   - Run with: `flutter test`

4. **Debugging**
   - Use `debugPrint()` for logs (visible in running app output)
   - Check Firebase Console for Auth/Firestore errors
   - Verify `mounted` in async contexts to catch frame updates on disposed widgets

## Dependencies & Versions

See [pubspec.yaml](pubspec.yaml) for full list. Key ones:
- **Flutter:** SDK >=3.2.3 <4.0.0
- **Firebase:** firebase_core, firebase_auth, cloud_firestore (v4.x)
- **State:** provider (v6.1.1) — currently minimal use
- **UI:** google_fonts, flutter_animate, cupertino_icons
- **Data:** shared_preferences, intl, http

## Environment Setup

1. **Flutter SDK:** Install from [flutter.dev](https://flutter.dev)
2. **Firebase CLI:** `npm install -g firebase-tools` (for rule deployment, optional)
3. **Android Studio / Xcode:** Required for respective platform builds
4. **Firebase Project:** Create at [console.firebase.google.com](https://console.firebase.google.com), link via FlutterFire CLI
5. **Google Sign-in:** Configure at Firebase Console (OAuth 2.0 credentials)

## Next Steps & Ideas

- **Add Game Stats Persistence:** Save wins, streaks, average guesses to Firestore
- **Multiplayer Mode:** Real-time puzzle sharing via Firestore
- **Offline Support:** Cache daily word to Firestore for offline play
- **Animations:** Expand `flutter_animate` usage for better UX
- **Test Suite:** Build out unit + widget tests for services and game logic
- **Error Boundary UI:** Centralized error handling/snackbars for better UX

## Links & Resources

- [Flutter Docs](https://docs.flutter.dev)
- [Firebase Docs](https://firebase.google.com/docs)
- [Wordle Rules](https://www.nytimes.com/games/wordle/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
