# Verdant 🌱

**Grow a virtual garden by keeping your habits.** A Flutter + Dart starter for the habit-tracker project (Aley, Nurul, Alicia, Jeff). It covers all 26 user stories in the backlog, with 19 hand-tuned plant species, 6 growth stages each, and 6 pot styles.

The app runs **out of the box with no backend**, using in-memory repositories and a seeded demo garden. When you're ready, switch to Firebase by changing a few lines in `main.dart` (see [`docs/FIREBASE.md`](docs/FIREBASE.md)).

---

## Quick start

```bash
# 1. Generate the platform folders (android/, ios/, web/ …) — lib/ and pubspec are kept
flutter create . --org com.verdant --project-name verdant

# 2. Get packages & run
flutter pub get
flutter run
```

**Demo login:** `demo@verdant.app` / `garden123`. This account is an admin, so you can see the App Updates screen.
**Password reset demo code:** `123456`
**Email failure demo:** send to any address ending in `@fail.test`
**Update failure demo:** the first install attempt fails partway, so you can try the Retry path.

Requires Flutter **3.24+** (Dart 3.4+).

---

## What's inside

```
lib/
  main.dart                     ← choose in-memory or Firebase backends here
  app.dart                      ← MaterialApp, theming, AuthGate (splash → welcome → home)
  core/
    theme/                      ← palette, accents, ThemeData + VerdantTokens extension
    widgets/plant_view.dart     ← ★ the plant renderer (pot back → plant → pot front), sway & tap rustle
    widgets/ui.dart             ← cards, pills, rings, bars, medals, buttons
  data/
    catalog/plant_catalog.dart  ← 19 species, 6 pots, 6 growth stages + thresholds
    catalog/habit_catalog.dart  ← 21 built-in habits
    catalog/badge_catalog.dart  ← 12 milestone badges
    models/                     ← Habit, Completion, EarnedBadge, UserProfile, AppSettings
    repositories/               ← interfaces + in-memory implementations & demo seed
  domain/rules.dart             ← completion validation, growth rules, stats (unit-tested)
  state/app_state.dart          ← single ChangeNotifier the UI listens to
  features/                     ← one folder per area (auth, today, garden, habits, progress, badges, share, profile, catalog)
assets/plants/<species>/stage_0..5.svg   ← generated plant art
assets/pots/<pot>_back.svg / _front.svg
tool/plant_art/                 ← the generator for all plant + pot SVGs
firebase_templates/             ← drop-in Firebase repositories + Firestore security rules
test/rules_test.dart
```

## Backlog → code map

| # | Story | Where |
|---|-------|-------|
| 1 | Register (unique username) | `features/auth/auth_screens.dart` → `RegisterScreen`, `InMemoryAuthRepository.register` |
| 2 | Log in + error on bad credentials | `LoginScreen` |
| 3 | Dashboard after login | `AuthGate` → `HomeShell` → `TodayScreen` |
| 4 | Log out | `ProfileScreen` → Log out (clears state & routes) |
| 5 | Browse built-in habits | `HabitLibraryScreen` → "Need ideas?" (a short list of 6 starting points; `HabitCatalog.suggestions`) |
| 6 | Add a habit | "Create your own habit" → `HabitSetupScreen` → `AppState.addHabit` (ideas open in the same form, prefilled and editable) |
| 7 | Target frequency + plant | `_RhythmPicker` (every day / weekly × N / every 2 weeks / monthly) and `_PlantPicker` (all 19 catalogue plants; habits on the same schedule share one plant, see `groupSpecies`) |
| 8 | Edit a habit (keeps history) | `HabitEditorScreen` |
| 9 | Remove habit (keeps history) | `HabitEditorScreen` → "Remove from tracking" → Garden ▸ Resting |
| 10 | Record a completion | `HabitCareTile` / plant detail → `completeWithFeedback` |
| 11 | Validate plant growth | `GrowthRules` (only accepted completions count) |
| 12 | Prevent duplicates | `CompletionRules` + deterministic completion ids (+ Firestore transaction) |
| 13 | View my plant | `PlantDetailScreen` |
| 14 | Interact with plant | Tap the plant → rustle animation + message bubble |
| 15 | Growth stages | Stage strip on plant detail + growth celebration |
| 16 | Progress toward goals | Progress ▸ "This week's goals" |
| 17 | Completion history | Progress ▸ History, plant detail ▸ Recent care |
| 18 | Progress over a period | Progress ▸ Week / Month / 3 Months |
| 19 | Earn badges (once) | `AppState._awardBadges` + `BadgeCatalog` |
| 20 | View earned badges | `BadgesScreen` |
| 21 | Available milestones | `BadgesScreen` ▸ Up next (with progress) |
| 22 | Share progress (privacy-aware) | `share_sheet.dart` → preview card, toggles, "Include habit names" off by default |
| 23 | Forgot password | `ForgotPasswordScreen` (request → code + new password → done) |
| 24 | Email habits & plants | `EmailShareScreen` (review → send → confirm / error) |
| 25 | Manage app updates (admin) | `UpdatesScreen` (details, install / later, retry on failure) |
| 26 | Design customization | `AppearanceScreen` (theme, accent, layout, home widgets, live preview, saved per user) |

## Growth rules

| Stage | Name | Valid completions |
|---|---|---|
| 0 | Seed | 0 |
| 1 | Sprout | 1 |
| 2 | Seedling | 3 |
| 3 | Growing | 7 |
| 4 | Mature | 14 |
| 5 | Blooming / Thriving / … | 24 |

Each habit can be logged once per day. Weekly habits can also be logged only up to their weekly target, and the count resets every Monday. Change the thresholds in `PlantCatalog.stages`.

## The plants

There are 19 species: Monstera, Snake Plant, Fiddle Leaf Fig, Echeveria, Saguaro Cactus, Boston Fern, Juniper Bonsai, Sunflower, Tulip, Lavender, Cherry Blossom, Peace Lily, Aloe Vera, Garden Rose, Bird of Paradise, Calathea, Golden Pothos (trails over the pot), Lucky Bamboo and Olive Tree.

All art is vector (SVG, about 2 MB total), so it stays sharp at any size. It's generated procedurally, so you can tweak it or add species:

```bash
node tool/plant_art/generate.mjs     # rewrites assets/plants and assets/pots
```

To add a species, write a `draw(doc, t, bloom, rng)` function in `tool/plant_art/species.mjs`, add it to `SPECIES`, regenerate, then add a matching entry to `PlantCatalog.species` and an asset line to `pubspec.yaml`.

## Design system

- **Type:** Fraunces (display, tight tracking) + Manrope (UI), via `google_fonts`
- **Colour:** ink `#0F1A14` / paper `#F3F0E8`, moss primary, lime highlight `#C6F36B`. There are 5 swappable accents, plus full dark mode.
- **Tokens:** `context.v` (card, line, muted, hero, highlight, `backdropFor(pot)`), `context.text`, `context.colors`
- **Motion:** ambient breeze sway, tap rustle, stage-up pop, elastic badge reveal, animated rings and bars

## Tests

```bash
flutter test
```
