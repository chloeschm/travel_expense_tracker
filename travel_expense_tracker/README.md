# Travel Expense Tracker

A full-featured Flutter app for tracking travel expenses across trips, built as a portfolio project. Supports real-time collaboration, AI-powered expense parsing, receipt scanning, and multi-currency conversion.

---

## Features

### Trips
- Create and manage multiple trips with destination, dates, and budget
- Invite others to join a trip via a shareable join code (e.g. `TR-4X9K`)
- Real-time sync across all members using Firestore live listeners
- Google Maps static thumbnail on every trip card

### Expenses
- Add expenses manually or use **AI Parse Text** — describe an expense in plain English and GPT-4o-mini fills in the details automatically
- **Scan a Receipt** using your camera or photo library — GPT-4o vision extracts the expense data
- Expenses grouped by category (Food, Transport, Accommodation, Activities, Shopping, Health, Other)
- Multi-currency support with live conversion rates
- Each expense shows who added it, great for group trips

### Budget Tracking
- Budget progress bar with remaining/over-budget indicator
- Total spent converted to trip currency across all members
- Per-category breakdowns

### Trip Summary
- Interactive donut chart showing spending by category
- Total spent and remaining budget stat cards
- Export a full PDF report with expense breakdown and per-category totals

### Profile
- Set your display name (shown on expenses you add in group trips)
- Set a preferred currency that pre-fills when creating trips or adding expenses

### Auth
- Email and password authentication via Firebase Auth
- Persistent sessions — stay logged in across app restarts

---

## Tech Stack

| Area | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend & Auth | Firebase (Firestore, Firebase Auth) |
| State Management | Provider |
| AI Parsing | OpenAI GPT-4o-mini (text), GPT-4o (vision) |
| Currency Conversion | ExchangeRate API |
| Maps | Google Maps Static API |
| Charts | fl_chart |
| PDF Export | pdf + printing packages |
| Image Picking | image_picker |

---

## Project Structure

```
lib/
├── main.dart               # App entry point + bottom nav shell
├── config.dart             # API keys (gitignored)
├── app_theme.dart          # Global theme and color constants
├── models/
│   ├── trip.dart
│   └── expense.dart
├── providers/
│   └── trip_provider.dart  # Firestore listeners, CRUD, profile
├── services/
│   └── currency.dart       # Exchange rate fetching and conversion
└── screens/
    ├── auth.dart
    ├── home.dart
    ├── profile.dart
    ├── add_trip.dart
    ├── trip_detail.dart
    ├── add_expense.dart
    └── trip_summary.dart
```

---

## Setup

1. Clone the repo
2. Create a Firebase project and add an Android/iOS app
3. Download `google-services.json` / `GoogleService-Info.plist` and place in the appropriate directories
4. Create `lib/config.dart` with your API keys:

```dart
class Config {
  static const String openAiApiKey = 'your-openai-key';
  static const String exchangeRateApiKey = 'your-exchangerate-key';
  static const String googleMapsApiKey = 'your-maps-key';
}
```

5. Run `flutter pub get` then `flutter run`

> `config.dart` and `firebase_options.dart` are gitignored and must be configured locally.

---

## Architecture Notes

- Expenses are stored as an **array field** on the trip document rather than a subcollection, which simplifies real-time listener logic
- `listenToTrips()` nests Firestore snapshot listeners — a top-level listener on `joinedTrips` sets up per-trip document listeners, so any expense change triggers an immediate UI rebuild
- API keys are kept in a gitignored `config.dart` for development; a production build would proxy these through a backend