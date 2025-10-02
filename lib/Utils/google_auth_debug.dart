import 'package:flutter/material.dart';
import 'google_auth_service.dart';
import 'firebase_auth_service.dart';

/// Google Auth Debug Helper
/// This provides debugging utilities for Google Sign-In
class GoogleAuthDebug {
  
  /// Run comprehensive debug information
  static Future<void> debugGoogleSignIn() async {
    print('🔍 Google Sign-In Debug Information:');
    print('=====================================');
    
    try {
      // Check Google Sign-In availability
      final isAvailable = await GoogleAuthService.isAvailable();
      print('📊 Google Sign-In available: $isAvailable');
      
      // Check if user is already signed in
      final isSignedIn = await GoogleAuthService.isSignedIn();
      print('📊 Currently signed in: $isSignedIn');
      
      // Check current user
      final currentUser = await GoogleAuthService.getCurrentUser();
      if (currentUser != null) {
        print('👤 Current user: ${currentUser.email}');
        print('👤 Display name: ${currentUser.displayName}');
        print('👤 ID: ${currentUser.id}');
      } else {
        print('👤 No current user');
      }
      
      // Check Firebase Auth state
      final firebaseUser = FirebaseAuthService.currentUser;
      if (firebaseUser != null) {
        print('🔥 Firebase user: ${firebaseUser.email}');
        print('🔥 Display name: ${firebaseUser.displayName}');
        print('🔥 UID: ${firebaseUser.uid}');
        print('🔥 Provider: ${firebaseUser.providerData.map((e) => e.providerId).join(', ')}');
      } else {
        print('🔥 No Firebase user');
      }
      
      // Get detailed status
      final status = await GoogleAuthService.getStatus();
      print('⚙️ Configuration status:');
      print('   - Initialized: ${status['initialized']}');
      print('   - Available: ${status['available']}');
      print('   - Signed in: ${status['signed_in']}');
      print('   - Has user: ${status['has_user']}');
      print('   - Firebase signed in: ${status['firebase_signed_in']}');
      
      print('✅ Debug information collected successfully');
      
    } catch (e) {
      print('❌ Error during debug: $e');
      print('🔍 Error type: ${e.runtimeType}');
    }
  }
  
  /// Test Google Sign-In flow
  static Future<void> testGoogleSignInFlow() async {
    print('🧪 Testing Google Sign-In Flow:');
    print('===============================');
    
    try {
      // Test 1: Check if sign in is available
      print('Test 1: Checking if Google Sign-In is available...');
      final isAvailable = await GoogleAuthService.isAvailable();
      if (isAvailable) {
        print('✅ Google Sign-In is available');
      } else {
        print('❌ Google Sign-In not available');
        return;
      }
      
      // Test 2: Try silent sign in
      print('Test 2: Attempting silent sign in...');
      try {
        final user = await GoogleAuthService.getCurrentUser();
        if (user != null) {
          print('✅ Silent sign in successful: ${user.email}');
        } else {
          print('ℹ️ No previous sign in found');
        }
      } catch (e) {
        print('⚠️ Silent sign in failed (expected if no previous sign in): $e');
      }
      
      // Test 3: Check authentication
      print('Test 3: Checking authentication...');
      try {
        final auth = await GoogleAuthService.getAuthentication();
        if (auth != null) {
          print('✅ Authentication available');
          print('   Access token: ${auth.accessToken != null ? 'Present' : 'Missing'}');
          print('   ID token: ${auth.idToken != null ? 'Present' : 'Missing'}');
        } else {
          print('ℹ️ No authentication available (no current user)');
        }
      } catch (e) {
        print('❌ Authentication check failed: $e');
      }
      
      print('✅ Google Sign-In flow test completed');
      
    } catch (e) {
      print('❌ Error during flow test: $e');
    }
  }
  
  /// Test the actual sign-in flow (interactive)
  static Future<Map<String, dynamic>> testSignInFlow() async {
    print('🚀 Testing interactive Google Sign-In flow...');
    
    try {
      final userCredential = await GoogleAuthService.signInWithFirebase();
      
      if (userCredential != null) {
        print('✅ Google Sign-In successful: ${userCredential.user?.email}');
        return {
          'success': true,
          'message': 'Sign-in successful',
          'user_email': userCredential.user?.email,
          'user_uid': userCredential.user?.uid,
        };
      } else {
        print('⚠️ Google Sign-In was cancelled');
        return {
          'success': false,
          'message': 'Sign-in was cancelled by user',
        };
      }
    } catch (e) {
      print('❌ Google Sign-In failed: $e');
      return {
        'success': false,
        'message': 'Sign-in failed: $e',
      };
    }
  }
  
  /// Test sign-out flow
  static Future<Map<String, dynamic>> testSignOutFlow() async {
    print('🚪 Testing Google Sign-In sign-out flow...');
    
    try {
      await GoogleAuthService.signOut();
      await FirebaseAuthService.signOut();
      
      // Check if user is actually signed out
      final isSignedIn = await GoogleAuthService.isSignedIn();
      final firebaseUser = FirebaseAuthService.currentUser;
      
      if (!isSignedIn && firebaseUser == null) {
        print('✅ Sign-out successful');
        return {
          'success': true,
          'message': 'Sign-out successful',
        };
      } else {
        print('❌ Sign-out failed - user still signed in');
        return {
          'success': false,
          'message': 'Sign-out failed - user still signed in',
        };
      }
    } catch (e) {
      print('❌ Sign-out failed: $e');
      return {
        'success': false,
        'message': 'Sign-out failed: $e',
      };
    }
  }
  
  /// Get current authentication status
  static Future<Map<String, dynamic>> getCurrentStatus() async {
    try {
      final status = await GoogleAuthService.getStatus();
      return {
        'success': true,
        'data': status,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get status: $e',
      };
    }
  }
  
  /// Reset everything (useful for testing)
  static Future<void> resetEverything() async {
    try {
      print('🔄 Resetting everything...');
      
      // Sign out from Firebase and Google
      await FirebaseAuthService.signOut();
      
      // Reset Google Auth Service
      GoogleAuthService.reset();
      
      print('✅ Everything reset successfully');
    } catch (e) {
      print('❌ Reset failed: $e');
    }
  }
}

