import 'package:flutter/foundation.dart';
import 'health_service.dart';

/// Helper class for debugging Health Connect integration
class HealthDebugHelper {
  static Future<void> runFullDiagnostic() async {
    debugPrint('=== HEALTH CONNECT DIAGNOSTIC FINAL ===');
    
    try {
      // Use the final, most robust Health Connect service
      final healthService = HealthService();
      
      // Run comprehensive diagnostic
      final diagnostic = await healthService.runDiagnostic();
      
      debugPrint('\n=== DIAGNOSTIC RESULTS ===');
      debugPrint('Health Connect Available: ${diagnostic['healthConnectAvailable']}');
      debugPrint('Runtime Permissions: ${diagnostic['runtimePermissions']}');
      debugPrint('Health Connect Permissions: ${diagnostic['healthConnectPermissions']}');
      debugPrint('Data Available: ${diagnostic['dataAvailable']}');
      debugPrint('Data Points Found: ${diagnostic['dataPointsFound']}');
      
      if (diagnostic['dataBreakdown'] != null) {
        debugPrint('\nData Breakdown:');
        (diagnostic['dataBreakdown'] as Map).forEach((key, value) {
          debugPrint('  $key: $value data points');
        });
      }
      
      if (diagnostic['errors'].isNotEmpty) {
        debugPrint('\n Errors found:');
        for (String error in diagnostic['errors']) {
          debugPrint('  - $error');
        }
      }
      
      if (diagnostic['success']) {
        debugPrint('\n Health Connect integration is working correctly!');
        debugPrint('   Found health data from your fitness tracker');
      } else {
        debugPrint('\n Health Connect integration has issues');
        debugPrint('   Check the errors above for details');
      }
      
    } catch (e) {
      debugPrint(' Error during diagnostic: $e');
      debugPrint('   This might be a Health Connect configuration issue');
    }
    
    debugPrint('\n=== DIAGNOSTIC COMPLETE ===');
  }
  
  /// Quick test to see if we can get any heart rate data
  static Future<void> quickHeartRateTest() async {
    debugPrint('=== QUICK HEART RATE TEST ===');
    
    try {
      final healthService = HealthService();
      await healthService.initialize();
      
      final heartRateData = await healthService.getLatestHeartRate();
      
      if (heartRateData != null) {
        debugPrint('Latest heart rate: ${heartRateData.value} bpm at ${heartRateData.dateFrom}');
        debugPrint(' Heart rate data is available!');
      } else {
        debugPrint(' No heart rate data found');
        debugPrint('   Make sure your fitness tracker is syncing with Health Connect');
      }
      
    } catch (e) {
      debugPrint(' Error in heart rate test: $e');
    }
    
    debugPrint('=== TEST COMPLETE ===');
  }
}
