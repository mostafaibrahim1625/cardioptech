import 'package:flutter/material.dart';
import 'google_auth_service.dart';
import 'firebase_auth_service.dart';
import 'google_auth_debug.dart';

/// Google Auth Test Utility
/// This provides comprehensive testing for Google Sign-In functionality
class GoogleAuthTest {
  
  /// Run all Google Auth tests
  static Future<Map<String, dynamic>> runAllTests() async {
    final results = <String, dynamic>{};
    
    try {
      print('🧪 Starting comprehensive Google Auth tests...');
      print('===============================================');
      
      // Test 1: Service initialization
      print('Test 1: Testing service initialization...');
      try {
        await GoogleAuthService.initialize();
        results['initialization'] = {'success': true, 'message': 'Service initialized successfully'};
        print('✅ Service initialization: PASSED');
      } catch (e) {
        results['initialization'] = {'success': false, 'message': 'Initialization failed: $e'};
        print('❌ Service initialization: FAILED - $e');
      }
      
      // Test 2: Availability check
      print('Test 2: Testing availability...');
      try {
        final isAvailable = await GoogleAuthService.isAvailable();
        results['availability'] = {'success': isAvailable, 'message': isAvailable ? 'Available' : 'Not available'};
        print('${isAvailable ? '✅' : '❌'} Availability check: ${isAvailable ? 'PASSED' : 'FAILED'}');
      } catch (e) {
        results['availability'] = {'success': false, 'message': 'Availability check failed: $e'};
        print('❌ Availability check: FAILED - $e');
      }
      
      // Test 3: Current status
      print('Test 3: Testing current status...');
      try {
        final status = await GoogleAuthService.getStatus();
        results['status'] = {'success': true, 'message': 'Status retrieved', 'data': status};
        print('✅ Status check: PASSED');
        print('   - Initialized: ${status['initialized']}');
        print('   - Available: ${status['available']}');
        print('   - Signed in: ${status['signed_in']}');
        print('   - Has user: ${status['has_user']}');
        print('   - Firebase signed in: ${status['firebase_signed_in']}');
      } catch (e) {
        results['status'] = {'success': false, 'message': 'Status check failed: $e'};
        print('❌ Status check: FAILED - $e');
      }
      
      // Test 4: Silent sign-in
      print('Test 4: Testing silent sign-in...');
      try {
        final user = await GoogleAuthService.getCurrentUser();
        if (user != null) {
          results['silent_signin'] = {'success': true, 'message': 'Silent sign-in successful', 'user_email': user.email};
          print('✅ Silent sign-in: PASSED - ${user.email}');
        } else {
          results['silent_signin'] = {'success': true, 'message': 'No previous sign-in found (expected)'};
          print('ℹ️ Silent sign-in: No previous user found (expected)');
        }
      } catch (e) {
        results['silent_signin'] = {'success': false, 'message': 'Silent sign-in failed: $e'};
        print('❌ Silent sign-in: FAILED - $e');
      }
      
      // Test 5: Authentication details
      print('Test 5: Testing authentication details...');
      try {
        final auth = await GoogleAuthService.getAuthentication();
        if (auth != null) {
          results['authentication'] = {'success': true, 'message': 'Authentication available', 'has_tokens': auth.accessToken != null && auth.idToken != null};
          print('✅ Authentication: PASSED - Tokens available');
        } else {
          results['authentication'] = {'success': true, 'message': 'No authentication (no current user)'};
          print('ℹ️ Authentication: No current user (expected)');
        }
      } catch (e) {
        results['authentication'] = {'success': false, 'message': 'Authentication check failed: $e'};
        print('❌ Authentication: FAILED - $e');
      }
      
      // Calculate overall success
      final allPassed = results.values.every((result) => 
        result is Map && result['success'] == true);
      results['overall_success'] = allPassed;
      
      print('===============================================');
      print('${allPassed ? '🎉' : '❌'} Overall test result: ${allPassed ? 'PASSED' : 'FAILED'}');
      
    } catch (e) {
      print('❌ Test suite failed with error: $e');
      results['error'] = e.toString();
    }
    
    return results;
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
  
  /// Quick health check
  static Future<bool> quickHealthCheck() async {
    try {
      await GoogleAuthService.initialize();
      final isAvailable = await GoogleAuthService.isAvailable();
      return isAvailable;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
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
  
  /// Run debug information
  static Future<void> runDebugInfo() async {
    await GoogleAuthDebug.debugGoogleSignIn();
  }
}

