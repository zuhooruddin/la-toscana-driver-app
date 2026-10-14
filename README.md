# La Toscana — driver app (Android / iOS)

Flutter app for La Toscana's delivery drivers. Same backend and database as the website, dashboard and other apps
(`/api/v1/driver/*`); drivers only ever see their own assignments.

## Features

- Branded login, compact delivery filters, delivery details/progress, route handoff, completion screen, account drawer and settings
- Spanish and English throughout the interface; change ES/EN on login, in the account drawer or in Settings. The choice is saved on the device.
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
adb reverse tcp:4000 tcp:4000
flutter run --dart-define=API_URL=http://127.0.0.1:4000
```

Checks: `flutter analyze`, `flutter test`. Release builds are HTTPS only and need the client's signing keys.
# la-toscana-driver-app

For a USB-connected physical Android device, keep the backend running on port 4000 and repeat adb reverse after reconnecting the device. For Wi-Fi on the same network, pass --dart-define=API_URL=http://192.168.1.6:4000 (update the IP if it changes). Android emulators can use --dart-define=API_URL=http://10.0.2.2:4000.
