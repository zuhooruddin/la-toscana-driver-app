# La Toscana — driver app (Android / iOS)

Flutter app for La Toscana's delivery drivers. Same backend and database as the website, dashboard and other apps
(`/api/v1/driver/*`); drivers only ever see their own assignments.

## Features

- Sign in (driver accounts only, created in the dashboard), forced change of the temporary password
- Live assignments (Socket.IO driver room + 30 s resync), vibration + sound for a new assignment
- Accept / decline; "waiting for the kitchen" until the order is marked ready; picked up → out for delivery; delivered
- Address with notes, items, **cash to collect** (or "paid by card"), navigate (Google Maps), call the customer
- History with today's cash total
- **Location sharing**: off by default; only with the driver's explicit consent, only while one of their orders is out for
  delivery, only while the app is open (no background location), at most every 15 s. The API refuses location for any
  other state, and the position is erased when the order is delivered.

## Run

```bash
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:4000
```

Checks: `flutter analyze`, `flutter test`. Release builds are HTTPS only and need the client's signing keys.
