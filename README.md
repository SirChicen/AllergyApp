# AllerAI - Smart Menu Analysis for Food Allergies

AllerAI is a Flutter mobile application that helps users with food allergies safely navigate restaurant menus using Claude AI Vision to analyze photos and provide safety ratings.

## 🎯 Core Features

- **Smart Menu Scanning**: Use your phone's camera to photograph restaurant menus
- **AI-Powered Analysis**: Powered by Claude AI Vision for accurate allergen detection
- **Safety Ratings**: Color-coded system (🟢 Safe, 🟡 Caution, 🔴 Avoid)
- **Canadian Standards**: Supports all 11 major allergens as defined by Health Canada
- **Personalized Profiles**: Save your specific allergen profile for quick analysis
- **Local Storage**: All user data stored securely on your device

## 🛠️ Technology Stack

- **Framework**: Flutter (Cross-platform iOS/Android)
- **Architecture**: Clean Architecture with MVVM pattern
- **AI Analysis**: Claude 3.5 Sonnet with Vision capabilities
- **Storage**: SharedPreferences for user settings
- **State Management**: StatefulWidget with local state

## 📱 Supported Allergens

AllerAI identifies all 11 major allergens recognized by Health Canada:

1. **Peanuts** - Ground nuts and peanut-derived products
2. **Tree Nuts** - Almonds, walnuts, cashews, etc.
3. **Sesame** - Sesame seeds, tahini, sesame oil
4. **Milk/Dairy** - All dairy products and lactose
5. **Eggs** - Chicken eggs and egg-derived ingredients
6. **Fish** - All finfish species and fish products
7. **Shellfish** - Crustaceans and mollusks
8. **Soy** - Soybeans and soy-derived products
9. **Wheat/Gluten** - Wheat flour and gluten-containing grains
10. **Mustard** - Mustard seeds and prepared mustard
11. **Sulphites** - Sulfur dioxide and sulfite preservatives

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0+)
- Android Studio / VS Code with Flutter extensions
- iOS/Android device or simulator
- Claude API key from Anthropic

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/SirChicen/AllergyApp.git
   cd AllergyApp
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Claude API**:
   - Get your API key from https://console.anthropic.com/
   - Open `lib/core/services/claude_service.dart`
   - Replace `'YOUR_CLAUDE_API_KEY_HERE'` with your actual API key

4. **Run the app**:
   ```bash
   # For iOS
   flutter run -d "iPhone 15 Pro"
   
   # For Android
   flutter run -d emulator-5554
   ```

### Project Structure

```
lib/
├── core/
│   ├── constants/         # Allergen definitions and app constants
│   ├── models/           # Data models for analysis results
│   └── services/         # Claude API service
├── screens/              # UI screens and pages
│   ├── welcome_screen.dart          # Splash screen
│   ├── first_time_setup_screen.dart # Initial allergen selection
│   ├── home_screen.dart             # Main scanning interface
│   ├── results_screen.dart          # Analysis results display
│   └── allergen_settings_screen.dart # Allergen preferences
└── main.dart            # App entry point
```

## 🔒 Safety & Legal

### Important Disclaimers

⚠️ **AllerAI is an informational tool only and should NOT replace professional medical advice**

- Always verify ingredients with restaurant staff
- Be aware of cross-contamination risks
- This app cannot detect all potential allergens
- Users are responsible for their own safety decisions

### Privacy

- All user data is stored locally on your device
- No personal information is sent to external servers
- Allergen profiles remain private and under your control
- Images are only sent to Claude API for analysis and are not stored

## 🧪 Testing

Run the test suite:

```bash
# Unit and widget tests
flutter test

# Code analysis
flutter analyze

# Format code
dart format .
```

## 📊 API Integration

### Claude AI Vision

- **Purpose**: Complete menu image analysis and allergen identification
- **Input**: Menu photos with user allergen profile
- **Output**: Structured analysis with safety ratings and reasoning
- **Cost**: ~$0.01-0.10 per analysis depending on image complexity

## 🎨 User Interface

### Design Principles

- **Safety First**: Clear, color-coded safety indicators
- **Accessibility**: High contrast, readable fonts, intuitive icons
- **Minimalism**: Clean interface focused on core functionality
- **Mobile-Optimized**: Portrait orientation, one-handed use

### Color Coding System

- 🟢 **Green (Safe)**: No allergens detected
- 🟡 **Yellow (Caution)**: Uncertain ingredients or possible allergens
- 🔴 **Red (Avoid)**: Contains user's specific allergens

### Screen Flow

1. **Welcome Screen**: Splash screen with app branding
2. **First-Time Setup**: One-time allergen selection with disclaimers
3. **Home Screen**: Main interface with scan button and profile summary
4. **Results Screen**: Detailed analysis with item-by-item breakdown
5. **Settings Screen**: Modify allergen preferences anytime

## 🔧 Development

### Code Quality

- Follows Flutter best practices
- Clean Architecture pattern
- Comprehensive error handling
- Material Design 3 components

### Performance

- Optimized image compression before API calls
- Efficient state management
- Conservative analysis approach (better safe than sorry)

## 🚀 Deployment

### Build Commands

```bash
# Android APK
flutter build apk --release

# iOS (requires Xcode and Apple Developer account)
flutter build ios --release

# App Bundle for Play Store
flutter build appbundle --release
```

## 🤝 Contributing

We welcome contributions! Please submit pull requests for:

- Bug fixes and improvements
- UI/UX enhancements
- Test coverage expansion
- Documentation updates

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For technical support:

- Check `API_SETUP.md` for configuration help
- Create an issue on GitHub for bugs
- Review Claude API documentation for API-related issues

## 🙏 Acknowledgments

- Health Canada for allergen guidelines
- Anthropic for Claude AI capabilities
- Flutter team for the cross-platform framework
- Food allergy community for feedback and testing

---

**Remember**: This app is a helpful tool, but your safety is ultimately in your hands. Always verify with restaurant staff and trust your instincts when it comes to food safety.