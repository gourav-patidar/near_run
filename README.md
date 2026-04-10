# 🏃 NearRun - Running Tracker App

A modern Flutter application for tracking running activities, monitoring distance, pace, and maintaining a comprehensive run history with statistics and personal bests.

## 📋 Project Overview

NearRun is a feature-rich running tracker application built with Flutter. It allows users to:
- Track active runs with real-time GPS location
- View detailed run summaries and statistics
- Maintain a history of all completed runs
- Monitor personal performance metrics
- Customize user profile settings

## ✨ Features

### 1. **Home Screen**
   - Quick access to start/stop running activities
   - Display of current run status
   - Real-time metrics display

### 2. **Active Run Tracking**
   - GPS-based distance tracking using Geolocator
   - Real-time pace and speed monitoring
   - Run duration tracking
   - Location permissions handling

### 3. **Run History**
   - Complete list of all recorded runs
   - Sort and filter capabilities
   - Date-based organization
   - Quick access to run details

### 4. **Run Summary & Statistics**
   - Visual charts and graphs using FL Chart
   - Performance trends and analytics
   - Total distance, runs count, average pace
   - Best run metrics

### 5. **User Profile**
   - Personal information management
   - User preferences and settings
   - Account customization

## 🛠️ Tech Stack

### Core Framework
- **Flutter**: 3.35.5 (Channel: stable)
- **Dart**: 3.9.2
- **Target SDK**: 3.9.2+

### State Management
- **Provider** (v6.1.1) - Efficient state management solution

### Location & Maps
- **Geolocator** (v11.0.0) - GPS location tracking
- **Permission Handler** (v11.2.0) - Runtime permissions management

### Database
- **SQLite** (v2.3.2) - Local data persistence
- **Path Provider** (v2.1.2) - File system paths
- **Path** (v1.9.0) - Path utilities

### UI & Visualization
- **FL Chart** (v0.66.2) - Advanced charts and graphs
- **Persistent Bottom Navigation Bar** (v6.2.1) - Navigation UI
- **Google Fonts** (v7.0.0) - Custom typography
- **Material Design** - Standard UI components

### Utilities
- **Intl** (v0.19.0) - Internationalization and date formatting

## 📁 Project Structure

```
lib/
├── main.dart                      # Application entry point
├── core/
│   ├── theme/                     # App theming and styles
│   │   └── app_text_styles.dart   # Text styling definitions
│   └── widgets/
│       └── app_bottom_nav.dart    # Bottom navigation bar
├── features/
│   ├── home/                      # Home screen feature
│   │   └── home_screen.dart
│   ├── active_run/                # Active run tracking feature
│   ├── history/                   # Run history feature
│   │   └── history_screen.dart
│   ├── run_summary/               # Summary & statistics feature
│   │   └── run_summary_screen.dart
│   └── profile/                   # User profile feature
│       └── profile_screen.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.35.5 or higher
- Dart 3.9.2 or higher
- Xcode (for iOS development)
- Android Studio (for Android development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd near_run
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### iOS
```bash
cd ios/
pod install
cd ..
flutter run
```

#### Android
- Ensure Android SDK is installed and configured
- Update `local.properties` with your Android SDK path
- Run with: `flutter run`

## 📱 Supported Platforms

- ✅ iOS (iPhone/iPad)
- ✅ Android (Phone/Tablet)
- ✅ Linux
- ✅ macOS
- ✅ Windows
- ✅ Web

## 🔐 Permissions

The app requires the following permissions:

### Android
- `ACCESS_FINE_LOCATION` - Precise GPS location tracking
- `ACCESS_COARSE_LOCATION` - Approximate location tracking

### iOS
- `NSLocationWhenInUseUsageDescription` - Location access while app is in use

## 📊 Database Schema

NearRun uses SQLite for local data storage with tables for:
- User profile information
- Run records (distance, duration, pace, location)
- Run statistics and metrics

## 🎨 Theming

The app includes a comprehensive theming system in `core/theme/` with:
- Light theme support
- Custom text styles
- Color schemes
- Material Design compliance

## 🧪 Testing

Run tests with:
```bash
flutter test
```

Widget tests are available in the `test/` directory.

## 📝 Build Information

- **Version**: 1.0.0+1
- **Publish Status**: Private (publish_to: 'none')

## 🔄 Development Workflow

1. Feature development follows the `features/` folder structure
2. Core utilities and themes go in the `core/` folder
3. All state management uses Provider pattern
4. Material Design principles are followed for UI

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [Geolocator Documentation](https://pub.dev/packages/geolocator)
- [FL Chart Documentation](https://pub.dev/packages/fl_chart)

## 📄 License

This project is private and proprietary.

## 👤 Author

Developed by Gourav Dev Team

---

**Happy Running! 🏃‍♂️**
