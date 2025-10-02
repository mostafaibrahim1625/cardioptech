
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite/sqflite.dart';
import 'Screens/Medicine Reminder/notifications/medicine_notification_service.dart';
import 'Utils/auth_wrapper.dart';
import 'Utils/health_service.dart';
import 'Utils/image_preloader.dart';
import 'Utils/google_auth_service.dart';
import 'core/di/service_locator.dart';

void main() async {
  // Ensure Flutter binding is initialized before any plugin calls
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (essential for app functionality)
  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Failed to initialize Firebase: $e');
  }
  
  // Initialize Google Auth Service
  try {
    print('🔧 Initializing Google Auth Service...');
    await GoogleAuthService.initialize();
    print('✅ Google Auth Service initialized');
  } catch (e) {
    print('❌ Failed to initialize Google Auth Service: $e');
  }
  
  // Initialize dependency injection (essential)
  ServiceLocator().init();
  print(' Dependency injection initialized');
  
  // Run app immediately - defer heavy initialization
  runApp(const CardioPTechApp());
  
  // Initialize other services in background after app starts
  _initializeServicesInBackground();
}

// Initialize heavy services in background to prevent app hanging
void _initializeServicesInBackground() async {
  try {
    // Preload critical images
    print(' Preloading critical images...');
    await ImagePreloader.preloadCriticalImages();
    print(' Critical images cached');
  } catch (e) {
    print(' Failed to preload critical images: $e');
  }
  
  try {
    // Test sqflite plugin
    print(' Testing sqflite plugin...');
    await getDatabasesPath();
    print(' sqflite plugin is available');
  } catch (e) {
    print(' sqflite plugin test failed: $e');
  }
  
  try {
    // Initialize notification service
    print('🔔 Initializing notification service...');
    await MedicineNotificationService().initialize();
    print(' Notification service initialized');
  } catch (e) {
    print(' Failed to initialize notification service: $e');
  }
  
  try {
    // Initialize health service (this can be heavy on MediaTek devices)
    print('🏥 Initializing health service...');
    await HealthService().initialize();
    print(' Health service initialized');
  } catch (e) {
    print(' Failed to initialize health service: $e');
  }
}

class CardioPTechApp extends StatelessWidget {
  const CardioPTechApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "CardioPTech",
      navigatorKey: NavigationService.navigatorKey,
      home: const AuthWrapper(),
    );
  }
}
