# PaperScan — Flutter Android

PaperScan is an offline-first document scanner and PDF utility app. Free scanning remains unlimited. PDF files and generated documents are stored locally on the device by default.

## Included

- ML Kit Document Scanner flow: camera scan, auto edge/crop/cleanup UI, multi-page scans.
- Create PDFs from scans and imported photos; import existing PDFs.
- Local library: search, rename, delete, view, share.
- Light/dark mode.
- PDF Workbench: merge, split/extract a page range, structure optimization, text extraction to TXT, text-only PDF-to-DOCX, PDF-to-PNG page export, OCR of selected images, add text, typed signature overlay, watermark, highlight matching selectable text, fill existing PDF text form fields (flattened), password protect/unlock, rotate pages.
- Premium product storefront, Google Play purchase query/purchase/restore listener wiring.
- AdMob banner widget using Google's test ad ID, limited to the Home/library navigation.

## Run

1. Install Flutter and Android SDK.
2. Open this folder in VS Code.
3. This starter archive is missing the Android Gradle wrapper files. From the project root, run the included PowerShell repair script once: `powershell -ExecutionPolicy Bypass -File scripts\bootstrap_android_wrapper.ps1`. It backs up PaperScan configuration, generates the wrapper with Flutter, then restores the app configuration.
4. Run `flutter pub get`.
5. Run `flutter analyze`, then `flutter run` on an Android device/emulator.

## Important configuration before publishing

### Google Play Billing

Create these products in Play Console:

- `paperscan_pro_monthly`
- `paperscan_pro_yearly`
- `paperscan_pro_lifetime`

Configure pricing, subscription periods, license testers and test through a Play Store internal test track. Current purchase handling listens for purchased/restored events and stores a local flag. **It does not validate purchase tokens with a secure backend, check subscription expiry, or synchronize entitlement across devices.** Do not use the local flag as a secure production entitlement.

### AdMob

The app currently uses Google-provided **test** App ID and banner IDs. Replace them with your own IDs only after setting up a privacy/consent flow, privacy disclosures, and policy review. There are no interstitial ads during scanning or document editing.

### Syncfusion PDF licensing

The PDF manipulation features use `syncfusion_flutter_pdf`. Review Syncfusion's current license and eligibility requirements for its Community License or commercial license before distributing or monetizing the app.

## Feature limits to understand

- PDF-to-Word creates a basic editable DOCX from text extracted from the PDF. It does not reconstruct the original layout, fonts, tables or embedded images. Image-only PDFs need OCR first; OCR currently works on selected images/photos, not automatically on all PDF pages.
- PDF compression rewrites the document and applies PDF structure compression. It may not reduce the size of every PDF and does not currently downsample embedded images.
- Merge uses page templates to preserve page appearance; interactive form fields/annotations may not survive as editable elements.
- Typed signatures are text overlays, not certificate-backed digital signatures.
- PDF form filling currently handles existing text fields and flattens the fields when saving. Checkbox/radio field editing is not included.
- OCR output is saved/shared as text. OCR language is Latin by default.
- The AdMob widget is in test mode. No production ad revenue IDs are configured.
- Premium feature access is not securely gated in this development build. Secure receipt validation and entitlement checks must be implemented before enabling paid access in a release build.

## Privacy

Scanning, OCR and PDF processing are on-device. PaperScan does not have a document-upload backend or cloud account system in this build. Ads are configured with a non-personalized test request; production ad consent and privacy controls still need implementation before replacing test IDs.
