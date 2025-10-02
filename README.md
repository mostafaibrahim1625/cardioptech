# CardioPTech - Heart Disease Management App

A Flutter application for heart disease management featuring health monitoring, medication reminders, AI assistance, and educational resources.

## Overview

CardioPTech is a health management application focused on cardiovascular health. It integrates with Android Health Connect for real-time health monitoring, provides medication reminders, includes an AI assistant for heart disease management, and offers educational content for patients and caregivers.

## Key Features

### Health Monitoring
- Real-time health data integration with Android Health Connect
- Heart rate tracking with timestamps
- Blood oxygen saturation monitoring
- Calorie burn tracking
- Sleep duration and quality monitoring
- Daily steps and distance tracking
- Workout session tracking

### Medicine Reminder System
- Local notifications for medication schedules
- SQLite-based medicine management
- Support for various medication types
- Customizable reminder schedules
- Visual medicine management interface

### AI Health Assistant
- Specialized chatbot for heart disease management
- Covers diet plans, exercise routines, and medication adherence
- Real-time health-related query responses
- Emphasizes consulting healthcare professionals for medical decisions

### Learning Center
- Comprehensive heart disease management resources
- YouTube integration for educational videos
- Organized topic categories
- Learning progress tracking

### Doctor Connection
- Healthcare provider locator
- Digital medical information storage
- Emergency contact management

### Authentication & Security
- Firebase authentication
- Google Sign-In integration
- Secure data handling and storage

## Technical Stack

### Frontend
- Flutter: Cross-platform mobile development
- Dart: Programming language
- Material Design: UI/UX framework

### Backend & Services
- Firebase: Authentication and backend services
- SQLite: Local database for medicine reminders
- Health Connect: Android health data integration
- Local Notifications: Medicine reminder system

### Key Dependencies
```yaml
# State Management
flutter_bloc: ^8.1.6
bloc: ^8.1.4

# Health & Monitoring
health: ^13.2.0
permission_handler: ^11.3.1

# Database & Storage
sqflite: ^2.4.2
shared_preferences: ^2.2.2

# Authentication
firebase_auth: ^5.3.1
google_sign_in: ^6.2.1

# Notifications
flutter_local_notifications: ^17.2.2

# UI Components
fl_chart: ^1.1.1
percent_indicator: ^4.2.5
google_fonts: ^6.3.2
```

## Platform Support

- Android: Full support with Health Connect integration
- iOS: Basic support (limited health data access)
- Web: Limited functionality
- Windows/Linux/macOS: Basic support

## Getting Started

### Prerequisites
- Flutter SDK (^3.9.0)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup
- Google Play Services (for Android)

### Installation

1. Clone the repository
   ```bash
   git clone <repository-url>
   cd heart_ai
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Firebase Setup
   - Create a Firebase project
   - Download `google-services.json` and place it in `android/app/`
   - Configure Firebase Authentication
   - Enable Google Sign-In

4. Health Connect Setup
   - Ensure target device has Health Connect installed
   - Grant necessary permissions for health data access

5. Run the application
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   └── di/                    # Dependency injection
├── data/
│   ├── models/               # Data models
│   ├── repositories/         # Data repositories
│   └── services/            # External services
├── domain/
│   ├── repositories/        # Repository interfaces
│   └── usecases/           # Business logic
├── Screens/
│   ├── AI Assitant/        # AI chat interface
│   ├── Auth/               # Authentication screens
│   ├── Doctor Connection/  # Doctor finder
│   ├── Learning/           # Educational content
│   ├── Medicine Reminder/  # Medication management
│   └── Settings/           # App settings
├── UI Components/          # Reusable UI widgets
├── Utils/                  # Utility functions and services
└── main.dart              # App entry point
```

## Configuration

### Android Configuration
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Health Connect: Required for health data access
- Permissions: Health, notifications, storage

### Firebase Configuration
- Authentication: Email/password and Google Sign-In
- Project Setup: Follow the `GOOGLE_AUTH_SETUP.md` guide
- Security Rules: Configure appropriate access rules

## Health Data Integration

The app integrates with Android Health Connect to provide:
- Real-time health metrics
- Historical data analysis
- Permission-based data access
- Secure data handling

### Supported Health Metrics
- Heart Rate (BPM)
- Blood Oxygen Saturation (%)
- Active Energy Burned (calories)
- Sleep Duration (hours)
- Steps Count
- Distance Traveled
- Workout Sessions

## Notification System

### Medicine Reminders
- Local Notifications: Scheduled medication alerts
- Customizable Timing: Flexible reminder schedules
- Multiple Medicines: Support for complex medication regimens
- Persistent Storage: Reminders survive app restarts

## AI Assistant Features

### Specialized Heart Disease Management
- Diet Plans: DASH and Mediterranean diet guidance
- Exercise Routines: Safe workouts for heart patients
- Medication Information: Drug interaction and adherence tips
- Vital Signs Management: Blood pressure and cholesterol guidance
- Stress Management: Heart-healthy stress reduction techniques
- Warning Signs: Recognition of emergency symptoms

## UI/UX Design

### Design Principles
- Accessibility: High contrast and readable fonts
- User-Friendly: Intuitive navigation and clear information hierarchy
- Health-Focused: Calming colors and medical imagery
- Responsive: Adapts to different screen sizes

### Color Scheme
- Primary: Medical blue (#2E7D8A)
- Secondary: Heart red (#E74C3C)
- Accent: Success green (#27AE60)
- Background: Clean white and light gray

## Privacy & Security

### Data Protection
- Local Storage: Sensitive data stored locally
- Encryption: Secure data transmission
- Permissions: Minimal required permissions
- User Control: Full control over data sharing

### Health Data Privacy
- No Cloud Storage: Health data remains on device
- Permission-Based: User controls data access
- Secure Transmission: Encrypted data transfer
- Compliance: Follows health data regulations

## Testing

### Test Coverage
- Unit Tests: Core functionality testing
- Widget Tests: UI component testing
- Integration Tests: End-to-end testing
- Health Service Tests: Health data integration testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/health_service_test.dart

# Run with coverage
flutter test --coverage
```

## Deployment

### Android
1. Build Release APK
   ```bash
   flutter build apk --release
   ```

2. Build App Bundle
   ```bash
   flutter build appbundle --release
   ```

3. Upload to Play Store
   - Follow Google Play Console guidelines
   - Ensure Health Connect compliance
   - Test on various devices

### iOS
1. Build iOS App
   ```bash
   flutter build ios --release
   ```

2. Xcode Configuration
   - Configure signing certificates
   - Set up provisioning profiles
   - Test on physical devices

## Performance Optimization

### App Performance
- Image Preloading: Critical images cached on startup
- Lazy Loading: Content loaded as needed
- Background Services: Health data synced in background
- Memory Management: Efficient resource usage

### Health Data Performance
- Batch Processing: Efficient data retrieval
- Caching: Local data caching for quick access
- Error Handling: Robust error recovery
- Background Sync: Non-blocking data updates

## Troubleshooting

### Common Issues

#### Health Data Not Loading
- Ensure Health Connect is installed
- Check app permissions
- Verify device compatibility
- Restart the app

#### Google Sign-In Issues
- Check `google-services.json` configuration
- Verify Firebase project setup
- Ensure Google Play Services is available
- Test on physical device

#### Notification Issues
- Check notification permissions
- Verify notification channels
- Test on different Android versions
- Check battery optimization settings

### Debug Mode
Enable debug logging by setting `kDebugMode` to true in development builds.

## Contributing

### Development Guidelines
1. Follow Flutter/Dart style guidelines
2. Write comprehensive tests
3. Document new features
4. Ensure accessibility compliance
5. Test on multiple devices

### Code Style
- Use meaningful variable names
- Add comments for complex logic
- Follow BLoC pattern for state management
- Implement proper error handling

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

### Getting Help
- Check the troubleshooting section
- Review the `GOOGLE_AUTH_SETUP.md` guide
- Test using the built-in test screens
- Check console output for debug information

### Contact
For technical support or feature requests, please open an issue in the repository.

## Future Enhancements

### Planned Features
- Wearable Integration: Support for smartwatches
- Telemedicine: Video consultation features
- Advanced Analytics: Detailed health trend analysis
- Family Sharing: Multi-user support
- Emergency Features: SOS and emergency contacts
- Medication Interaction Checker: Drug interaction warnings

### Roadmap
- Q1 2024: Wearable device integration
- Q2 2024: Advanced health analytics
- Q3 2024: Telemedicine features
- Q4 2024: Family sharing capabilities

---

**Disclaimer**: This application is designed to assist with heart disease management but should not replace professional medical advice. Always consult with healthcare professionals for medical decisions and emergency situations.