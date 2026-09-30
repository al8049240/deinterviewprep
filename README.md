# Flutter

A modern Flutter-based mobile application utilizing the latest mobile development technologies and tools for building responsive cross-platform applications.

## 📋 Prerequisites

- Flutter SDK (^3.38.4)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

## 🛠️ Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:

To run the app with environment variables defined in an env.json file, follow the steps mentioned below:
1. Through CLI
    ```bash
    flutter run --dart-define-from-file=env.json
    ```
2. For VSCode
    - Open .vscode/launch.json (create it if it doesn't exist).
    - Add or modify your launch configuration to include --dart-define-from-file:
    ```json
    {
        "version": "0.2.0",
        "configurations": [
            {
                "name": "Launch",
                "request": "launch",
                "type": "dart",
                "program": "lib/main.dart",
                "args": [
                    "--dart-define-from-file",
                    "env.json"
                ]
            }
        ]
    }
    ```
3. For IntelliJ / Android Studio
    - Go to Run > Edit Configurations.
    - Select your Flutter configuration or create a new one.
    - Add the following to the "Additional arguments" field:
    ```bash
    --dart-define-from-file=env.json
    ```

### Test Serious Mode without purchasing

Serious Mode is unlocked automatically in debug builds:

```bash
flutter run --dart-define-from-file=env.json
```

Profile and release builds do not receive this development unlock and require
a valid purchased or server-managed entitlement.

### Configure Google Play purchase verification

Lifetime purchases are verified by the `verify-play-purchase` Supabase Edge
Function before Pro access is granted. Apply the Supabase migrations, create a
Google Cloud service account with access to the app in Google Play Console,
and store the complete service-account JSON as a function secret:

```bash
supabase secrets set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON='<service-account-json>'
supabase functions deploy verify-play-purchase
```

Never put the service-account JSON or the Supabase service-role key in the
Flutter app. The Edge Function verifies the signed-in user and the Google Play
purchase, then writes `de_mobile_app.user_entitlements` with admin credentials.

## 📁 Project Structure

```
flutter_app/
├── android/            # Android-specific configuration
├── ios/                # iOS-specific configuration
├── lib/
│   ├── core/           # Core utilities and services
│   │   └── utils/      # Utility classes
│   ├── presentation/   # UI screens and widgets
│   │   └── splash_screen/ # Splash screen implementation
│   ├── routes/         # Application routing
│   ├── theme/          # Theme configuration
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # Application entry point
├── assets/             # Static assets (images, fonts, etc.)
├── pubspec.yaml        # Project dependencies and configuration
└── README.md           # Project documentation
```

## 🧩 Adding Routes

To add new routes to the application, update the `lib/routes/app_routes.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:package_name/presentation/home_screen/home_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    // Add more routes as needed
  }
}
```

## 🎨 Theming

This project includes a comprehensive theming system with both light and dark themes:

```dart
// Access the current theme
ThemeData theme = Theme.of(context);

// Use theme colors
Color primaryColor = theme.colorScheme.primary;
```

The theme configuration includes:
- Color schemes for light and dark modes
- Typography styles
- Button themes
- Input decoration themes
- Card and dialog themes

## 📱 Responsive Design

The app is built with responsive design using the Sizer package:

```dart
// Example of responsive sizing
Container(
  width: 50.w, // 50% of screen width
  height: 20.h, // 20% of screen height
  child: Text('Responsive Container'),
)
```
## 📦 Deployment

### In-app purchase setup

Create these **non-consumable** products in both App Store Connect and Google
Play Console. The price shown in the app always comes from the active store, so
configure the USD base price and regional tiers there.

| Product ID | Price | Purpose |
| --- | ---: | --- |
| `de_interview_prep_lifetime_launch` | $5.00 | Limited launch promotion |
| `de_interview_prep_lifetime` | $10.00 | Normal lifetime purchase |

Launch builds use the promotional product by default. Build the normal-price
version with:

```bash
flutter build appbundle --release \
  --dart-define=IAP_LAUNCH_PROMOTION=false \
  --dart-define-from-file=env.json
```

For an automatic 45-day launch window, provide the public release timestamp in
UTC. The app uses the $5 launch product through the end of the window and then
switches to the $10 lifetime product automatically:

```bash
flutter build appbundle --release \
  --dart-define=IAP_LAUNCH_PROMOTION=true \
  --dart-define=IAP_LAUNCH_START_UTC=2026-10-01T00:00:00Z \
  --dart-define-from-file=env.json
```

If `IAP_LAUNCH_START_UTC` is omitted, the launch promotion remains enabled for
backward compatibility. Use the actual Production release timestamp, not the
internal-testing date.

Before publishing, replace the placeholder Android application ID and debug
release signing configuration, configure the matching iOS bundle ID, accept
the stores' paid-app agreements, and test purchase and restore flows with
sandbox/license-test accounts.

The client validates the store transaction data before granting local access.
For a large-scale production launch, send the receipt to a trusted backend for
server-side verification and cross-device entitlement synchronization.

Build the application for production:

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

## 🙏 Acknowledgments
- Built with [Rocket.new](https://rocket.new)
- Powered by [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Styled with Material Design

Built with ❤️ on Rocket.new
