# Smart DSS AI Assistant 🚀

A professional **AI-Assisted Decision Support System** built with Flutter. This app guides users through complex decision-making processes using a structured conversational interface and calculates rankings using standard DSS methods (**SAW, WP, and TOPSIS**).

Created with ❤️ by:
- **Prima Adi**
- **Ade Dwi**

---

## Features

- **Guided AI Interview**: Uses DeepSeek AI to walk you through defining a decision, criteria, and alternatives step-by-step.
- **Multiple Ranking Methods**:
  - **SAW** (Simple Additive Weighting)
  - **WP** (Weighted Product)
  - **TOPSIS**
- **Cloud Persistence**: Integrated with Firebase Firestore to save and sync your decision cases.
- **Modern UI**: Sleek Light Blue & Light Orange theme with Markdown support in chat.

---

## Setup Instructions

To get this project running locally on your machine, follow these steps:

### 1. Prerequisites
- Flutter SDK (latest stable)
- CocoaPods (for iOS developers)

### 2. Environment Variables
Create a `.env` file in the root directory and add your DeepSeek API key:
```env
DEEPSEEK_API_KEY=your_api_key_here
```

### 3. Firebase Configuration
Since sensitive config files are ignored in Git, you need to add your own:
- **iOS**: Place your `GoogleService-Info.plist` in `ios/Runner/`.
- **Android**: Place your `google-services.json` in `android/app/`.
- **Logic**: Run `flutterfire configure` if you have the FlutterFire CLI, or manually update `lib/firebase_options.dart`.

### 4. Install Dependencies
Run the following command to fetch all packages:
```bash
flutter pub get
```

### 5. Generate Models
This project uses `json_serializable`. Generate the necessary code by running:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Run the App
```bash
flutter run
```

---

## Architecture

- **Logic**: All DSS mathematical calculations are executed locally in `lib/logic/dss_engine.dart` (not by the AI).
- **AI**: DeepSeek handles the conversational data extraction in `lib/services/deepseek_service.dart`.
- **State Management**: Using `flutter_riverpod` for clean and reactive state.

---

## Contributing

1. Clone the repository.
2. Follow the setup instructions above.
3. Create a new branch for your feature.
4. Submit a Pull Request!
