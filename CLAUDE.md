# AllergyApp - Claude Code Session Guide

## 🎯 Project Overview
AllergyApp is a Flutter mobile application that helps users with food allergies safely navigate restaurant menus using OCR and AI analysis to identify potential allergens and provide safety ratings.

### Core Functionality
- Users photograph restaurant menus with their phone camera
- OCR extracts text from menu images (Google Vision API)
- AI analyzes menu items for allergens (OpenAI GPT-4o)
- App displays color-coded safety ratings: 🟢 Safe, 🟡 Caution, 🔴 Avoid
- Supports all 11 major allergens: peanuts, tree nuts, sesame, milk, egg, fish, shellfish, soy, wheat, mustard, sulphites

## 🛠️ Technology Stack

### Mobile Framework
- **Flutter** - Single codebase for iOS/Android
- **Architecture**: MVVM + Clean Architecture pattern
- **Database**: SQLite for local storage (user profiles, cached results)
- **State Management**: Provider/Riverpod (to be determined during implementation)

### External APIs
- **OCR**: Google Vision API ($1.50/1K pages, 98% accuracy)
- **AI Analysis**: OpenAI GPT-4o (~$0.01-0.06/1K tokens)
- **Cost Target**: ~$35-150/month for moderate usage

### Key Dependencies (Flutter)
```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.5
  image_picker: ^1.0.4
  sqflite: ^2.3.0
  http: ^1.1.0
  path_provider: ^2.1.1
  shared_preferences: ^2.2.2
  google_ml_vision: ^0.0.7 # or google_ml_kit
  image: ^4.1.3
```

## 📁 Project Structure
```
lib/
├── core/
│   ├── database/          # SQLite setup and migrations
│   ├── constants/         # App constants, allergen lists
│   ├── errors/           # Error handling
│   └── utils/            # Helper functions
├── data/
│   ├── models/           # Data models (Allergen, AnalysisResult, etc.)
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

## 🎨 Key UI Screens
1. **Onboarding** - Allergen profile setup, legal disclaimers
2. **Home** - Main navigation, profile summary
3. **Camera** - Photo capture, gallery selection
4. **Processing** - OCR/AI analysis progress
5. **Results** - Safety ratings, detailed analysis
6. **Profile** - Edit allergen preferences
7. **Settings** - App preferences, help

## 🔒 Critical Safety Requirements

### Conservative Analysis Approach
- **Target**: <1% false negative rate (saying safe when not safe)
- **Acceptable**: Higher false positive rate (better safe than sorry)
- **Positioning**: "Informational tool only" - NOT medical advice
- **Legal**: Prominent disclaimers, encourage restaurant staff verification

### AI Prompting Strategy
```
System: You are a food safety expert analyzing menu items for allergens.
Context: User allergies: [user_profile]
Task: Analyze this menu text for potential allergens.
Requirements: 
- Be conservative (err on side of caution)
- Identify hidden allergens (e.g., "butter" contains dairy)
- Assign confidence scores (0-100)
- Flag uncertain items for follow-up questions
Output: JSON with safety_rating, confidence, reasoning, allergens_detected
```

## 📊 Data Models

### User Allergen Profile
```dart
class AllergenProfile {
  List<String> selectedAllergens; // From 11 major allergens
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Analysis Result
```dart
class AnalysisResult {
  String menuItemText;
  SafetyRating rating; // GREEN, YELLOW, RED
  int confidenceScore; // 0-100
  List<String> detectedAllergens;
  String reasoning;
  List<String> followUpQuestions;
  DateTime analyzedAt;
}
```

### Major Allergens List
```dart
const List<String> MAJOR_ALLERGENS = [
  'peanuts', 'tree_nuts', 'sesame', 'milk', 'egg', 
  'fish', 'shellfish', 'soy', 'wheat', 'mustard', 'sulphites'
];
```

## 🔧 Development Commands

### Setup Commands
```bash
# Install Flutter dependencies
flutter pub get

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"

# Run on Android emulator  
flutter run -d emulator-5554

# Build for testing
flutter build apk --debug
flutter build ios --debug --no-codesign

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

### API Setup Required
1. **Google Cloud Vision API**
   - Enable Vision API in Google Cloud Console
   - Create service account and download JSON key
   - Add to `assets/` and reference in `pubspec.yaml`

2. **OpenAI API**
   - Get API key from OpenAI platform
   - Store securely (environment variables or secure storage)

## 📋 GitHub Issues Status
- **Total Issues**: 18 (MVP scope)
- **Repository**: https://github.com/SirChicen/AllergyApp
- **Current Phase**: Ready to start Issue #1 (Project Setup)

### Critical Path Order
1. Project Setup → 2. Database Setup → 3. Allergen Profile UI → 8. OCR Processing → 10. AI Analysis → 11. Safety Ratings → 14. Testing → 17. App Store Prep

### Parallel Work Opportunities
- Issues #5 (Camera) + #7 (Vision API) + #9 (OpenAI) can be developed simultaneously
- Issues #12 (Main UI) + #13 (Results UI) can be parallel
- Issues #15 (Polish) + #16 (Legal) can be parallel

## 🧪 Testing Strategy

### MVP Success Criteria
- OCR accuracy: >90% for clear menu text
- AI analysis: <1% false negative rate
- Full workflow (photo → results) in <60 seconds
- Handles 80%+ of common restaurant menu formats

### Test Cases Priority
1. **Critical**: False negative testing (dangerous allergens missed)
2. **High**: OCR accuracy across menu styles
3. **High**: AI analysis consistency
4. **Medium**: UI/UX usability
5. **Low**: Performance optimization

## 💰 API Cost Management

### Cost Optimization Strategies
- Cache identical menu items for 24-48 hours
- Optimize image quality before OCR (balance size vs accuracy)
- Efficient AI prompting to minimize tokens
- Batch process multiple menu items when possible

### Usage Monitoring
- Track API calls and costs
- Alert at 80% of monthly budget
- Implement usage quotas if needed

## 🔐 Privacy & Security
- All user data stored locally (SQLite)
- No user accounts or cloud storage required
- Allergen profiles persist between sessions locally
- Optional: Allow users to delete all data

## 📱 Platform Considerations

### iOS Specific
- Request camera permissions properly
- Handle different screen sizes (iPhone SE to Pro Max)
- Follow iOS Human Interface Guidelines

### Android Specific  
- Handle varied camera APIs across devices
- Support Android 6.0+ (API level 23+)
- Follow Material Design guidelines

## 🚀 Deployment Notes

### App Store Requirements
- Privacy policy (even for local-only data)
- Legal disclaimers prominently displayed
- Age rating: likely 4+ (no restricted content)
- Keywords: allergy, food safety, menu scanner, dietary restrictions

### Release Preparation
- App signing certificates
- Store listing assets (screenshots, descriptions)
- Beta testing with real users
- Performance testing on older devices

## 🆘 Common Issues & Solutions

### OCR Problems
- Poor image quality → Implement image preprocessing
- Wrong text extraction → Add text cleaning algorithms
- API rate limits → Implement retry logic with exponential backoff

### AI Analysis Issues
- Inconsistent responses → Refine prompting strategy
- High API costs → Implement intelligent caching
- False negatives → Make prompts more conservative

### Performance Issues
- Slow image processing → Optimize image size before API calls
- Memory usage → Implement proper image disposal
- Battery drain → Minimize background processing

## 📚 Key Documentation Links
- [Flutter Documentation](https://docs.flutter.dev/)
- [Google Vision API](https://cloud.google.com/vision/docs)
- [OpenAI API](https://platform.openai.com/docs/introduction)
- [SQLite Flutter Plugin](https://pub.dev/packages/sqflite)

---

## 🎯 Current Development Focus
**Next Task**: Issue #1 - Project Setup and Dependencies
**Goal**: Set up Flutter project with clean architecture and all required dependencies
**Timeline**: 1-2 days

Remember: This is a personal safety tool, not medical software. Always err on the side of caution and include appropriate disclaimers.