# ApexSaver - Savings Tracker

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

**ApexSaver Vault** is a professional, streamlined Flutter application dedicated to helping you track micro-savings targets, lock milestones, and optimize financial velocity benchmarks safely.

## 🎯 Features

- ✅ **User Authentication** - Secure Firebase authentication with email/password signup
- ✅ **Account Profile Setup** - Create and manage your profile with name, birthday, and profile picture
- ✅ **Savings Goals** - Create multiple savings goals with target amounts and deadlines
- ✅ **Ledger History** - Track deposits and withdrawals for each goal
- ✅ **Progress Visualization** - Beautiful charts showing savings growth
- ✅ **Gamification** - Unlock milestones and badges as you reach savings targets
- ✅ **Dynamic Pace Advice** - Get personalized weekly savings recommendations
- ✅ **Multi-Currency Support** - Support for different currencies
- ✅ **Goal Archiving** - Archive completed or inactive goals
- ✅ **Responsive Design** - Works on desktop, web, and mobile

## 📱 Platforms Supported

- **Windows** - Native desktop application
- **Web** - Browser-based access
- **iOS/macOS** - Mobile and desktop support (ready for deployment)
- **Android** - Mobile support (ready for deployment)

## 🛠 Tech Stack

### Frontend
- **Flutter & Dart** - Cross-platform UI framework
- **Material 3** - Modern design system

### State Management
- **Provider** - Reactive state management

### Backend & Authentication
- **Firebase Core** - Backend infrastructure
- **Firebase Authentication** - Secure user authentication
- **Cloud Firestore** - Cloud database for user profiles

### Local Storage
- **Hive** - Local NoSQL database for savings goals and transactions

### Data Visualization
- **FL Chart** - Professional charts for savings visualization

### Media & Images
- **Image Picker** - Select images for profiles and goals
- **Base64 Encoding** - Store images in cloud and local storage

### Additional Libraries
- **Intl** - Date/time formatting and localization
- **HTTP** - Network requests
- **Flutter Analog Clock** - Custom clock widgets
- **Provider** - Dependency injection and state management

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Firebase project setup
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/jmburnitdown-ops/savings_tracker.git
   cd savings_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a Firebase project at [https://console.firebase.google.com](https://console.firebase.google.com)
   - Download your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Run `flutterfire configure` to set up Firebase in your project

4. **Generate code**
   ```bash
   dart run build_runner build
   ```

5. **Run the app**
   ```bash
   # Desktop (Windows)
   flutter run -d windows

   # Web
   flutter run -d chrome

   # Mobile
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── login_page.dart                    # Authentication UI
├── firebase_options.dart              # Firebase configuration
├── models/
│   └── savings_models.dart            # Data models
├── providers/
│   ├── savings_provider.dart          # State management
│   ├── savings_provider.g.dart        # Generated code
│   └── currency_provider.dart         # Currency conversion
└── widgets/
    ├── animated_background.dart       # Background animations
    ├── digital_clock_widget.dart      # Clock display
    ├── goal_widgets.dart              # Savings goal UI
    └── profile_inspector.dart         # Profile management
```

## 🔐 Authentication

### Sign Up
- Enter email and password
- Provide first name, middle name (optional), last name
- Select birthday
- Account data saved to Firebase Firestore

### Sign In
- Login with registered email and password
- Profile data automatically loaded from Firebase
- Session maintained across app restarts

## 💰 Creating Savings Goals

1. **Add Goal**
   - Goal name
   - Target amount
   - Target deadline (optional)
   - Currency selection
   - Goal image (optional)

2. **Track Progress**
   - Add deposits to your goal
   - Record withdrawals
   - View full transaction history
   - Monitor progress with visual indicators

3. **Milestones & Badges**
   - 🚀 **First Step** - Made your first deposit
   - 🛡️ **Halfway Hero** - Reached 50% of target
   - 👑 **Apex Achiever** - Reached 100% of target

## 🎨 User Interface

- **Modern Design** - Material 3 design system
- **Dark Theme** - Professional dark interface
- **Responsive Layout** - Adapts to different screen sizes
- **Smooth Animations** - Professional animations and transitions
- **Intuitive Navigation** - Easy-to-use interface

## 🔧 Build & Deployment

### Build for Windows
```bash
flutter build windows --release
```

### Build for Web
```bash
flutter build web --release
```

### Build for Mobile
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
flutter build appbundle --release
```

## 📝 Development

### Code Generation
The project uses `build_runner` for code generation (Hive adapters, etc.):
```bash
dart run build_runner build
dart run build_runner watch  # For watching file changes
```

### Linting
```bash
dart analyze
```

### Testing
```bash
flutter test
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**John Mark M. Bangud**

- GitHub: [@jmburnitdown-ops](https://github.com/jmburnitdown-ops)
- Project: [ApexSaver Vault](https://github.com/jmburnitdown-ops/savings_tracker)

## 📞 Support

For support, email or open an issue on GitHub.

## 🙏 Acknowledgments

- [Flutter Documentation](https://flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Hive Database](https://docs.hivedb.dev)
- [FL Chart](https://github.com/imaNNeoFusion/fl_chart)

---

**Version:** 1.0.0  
**Last Updated:** June 2, 2026  
**© 2026 ApexSaver Studio. All rights reserved.**
