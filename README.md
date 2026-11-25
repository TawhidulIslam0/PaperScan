# PaperScan – Flutter Android project

PaperScan is an offline-first document scanning app concept. The included working core is camera document scanning via Google's on-device document scanner SDK, importing photos/PDFs, creating PDFs from image pages, local library storage, rename/delete, viewing, and sharing.

## Requirements
- Flutter stable (Dart 3.4+)
- Android SDK, Android device or emulator (document scanner module requires Android)

## Run
```bash
flutter pub get
flutter run
```

## Included now
- On-device document scanner (automatic edge detection/crop/cleaning UI provided by ML Kit Document Scanner)
- Scan to PDF; multi-page scanner; image import to PDF
- Import existing PDF
- Local document library, search, rename, delete
- PDF viewing and share
- Light/dark theme
- Premium storefront UI and in-app-purchase product query/buy/restore wiring

## Not production-ready / requires configuration or further implementation
- Google Play Billing: create product IDs `paperscan_pro_monthly`, `paperscan_pro_yearly`, `paperscan_pro_lifetime` in Play Console, configure prices and license testers, then test purchases and entitlement verification. This starter does not implement receipt verification or secure entitlement unlock.
- Advanced PDF tools (merge/split/annotation/OCR/conversion/password/compression) currently have premium landing entries only. They must be implemented and tested before charging for them.
- No ads are integrated in this project yet. AdMob requires app/ad IDs, privacy disclosures, consent handling and policy testing.
- Add your own Android launcher icons and app signing config for release.

## Privacy
Scanning and PDFs are stored locally in app-private storage by default. Imported PDFs are copied into the app library. The app does not upload documents to a server.
