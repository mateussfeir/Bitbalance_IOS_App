# BitBalance (iOS)

BitBalance is an iOS application that tracks a user's net worth and asset distribution.

## Milestone 1 – UI & Navigation

This milestone focuses on:
- Application structure
- Screen layout
- Navigation between views

### Implemented Features
- Net worth dashboard
- Asset category breakdown
- Navigation to category detail screens
- Composition pie chart from saved asset data
- Net worth history line chart (dummy data)
- Live crypto quotes through CoinGecko
- Configurable stock quotes through Alpha Vantage

> The composition pie chart now uses live portfolio composition data. The history chart still uses placeholder data.

## Tech Stack
- SwiftUI
- Swift Charts
- Xcode

## How to Run
Open the project in Xcode and run on any iOS simulator (iOS 16+).

## Stock Quote Setup
Crypto quotes work without setup. Stock quotes require an Alpha Vantage API key.

1. Open the `BitBalance` target in Xcode.
2. Copy `LocalSecrets.plist.example` to `LocalSecrets.plist`.
3. Put your real key in `LocalSecrets.plist` under `ALPHA_VANTAGE_API_KEY`.
4. `LocalSecrets.plist` is gitignored and will not be pushed.
5. Run the app again and use the refresh button.

Optional fallback:
- You can still set `ALPHA_VANTAGE_API_KEY` in Build Settings if you prefer.
- `PriceService` prefers `LocalSecrets.plist` first, then falls back to the generated `Info.plist` key.
