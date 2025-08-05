# AllergyApp

A Flutter mobile application that helps users with food allergies safely navigate restaurant menus using OCR and AI analysis to identify potential allergens and provide safety ratings.

## 🎯 Project Status

**Current Phase**: Issue #1 - Project Setup ✅ (COMPLETED)

### ✅ Completed Setup Tasks:
- Flutter project structure created with clean architecture
- All required dependencies added to `pubspec.yaml`
- Basic app configuration (Android/iOS permissions, metadata)
- 11 major allergens constants defined
- API configuration placeholders created
- Basic UI foundation with welcome screen
- Linting and analysis configuration

### 🔧 Manual Setup Required:

Due to Flutter CLI permission issues, please complete these manual steps:

1. **Fix Flutter Configuration (One-time setup)**:
   ```bash
   # Fix the .config directory permissions
   sudo chown -R $(whoami) ~/.config
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify Setup**:
   ```bash
   flutter doctor
   flutter analyze
   flutter test
   ```

4. **Run the App**:
   ```bash
   # iOS Simulator
   flutter run -d "iPhone 15 Pro"
   
   # Android Emulator
   flutter run -d emulator-5554
   ```

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/         # App constants, allergen lists, API config
│   ├── database/          # SQLite setup (Issue #2)
│   ├── errors/           # Error handling
│   └── utils/            # Helper functions
├── data/
│   ├── models/           # Data models
│   ├── repositories/     # Repository implementations
│   └── datasources/      # API clients, local storage
├── domain/
│   ├── entities/         # Business entities
│   ├── repositories/     # Repository interfaces
│   └── usecases/         # Business logic use cases
├── presentation/
│   ├── pages/            # App screens
│   ├── widgets/          # Reusable UI components
│   └── providers/        # State management
└── main.dart
```

## 🔑 Key Dependencies

- **Flutter**: Mobile framework
- **camera**: Photo capture functionality
- **google_mlkit_text_recognition**: OCR processing
- **http**: API communication
- **sqflite**: Local SQLite database
- **provider**: State management
- **image_picker**: Gallery selection

## 🚀 Next Steps (Issue #2)

1. Design and implement SQLite database schema
2. Create data models for allergen profiles and analysis results
3. Implement repository pattern for data access

## 📱 Core Features (MVP Scope)

- **Allergen Profile**: Select from 11 major allergens
- **Menu Scanning**: Camera integration for menu photos
- **OCR Processing**: Google Vision API text extraction
- **AI Analysis**: OpenAI GPT-4o allergen detection
- **Safety Ratings**: 🟢 Safe, 🟡 Caution, 🔴 Avoid
- **Local Storage**: SQLite for profiles and caching

## 🔐 API Configuration

Before running the app, configure your API keys in:
- `lib/core/constants/api_config.dart`

Required APIs:
- Google Vision API (OCR)
- OpenAI API (AI Analysis)

## 🎯 Success Criteria

- OCR accuracy: >90% for clear menu text
- AI analysis: <1% false negative rate
- Full workflow (photo → results) in <60 seconds
- Handles 80%+ of common restaurant menu formats

---

**Issue #1 Status**: ✅ COMPLETED
**Next Issue**: #2 - Database Schema and Local Storage Setup