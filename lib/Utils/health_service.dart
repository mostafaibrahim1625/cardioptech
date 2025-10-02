import 'package:health/health.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

/// Robust Health Connect service with comprehensive error handling
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  Health? _health;
  bool _isInitialized = false;
  String _lastError = '';
  bool _healthConnectAvailable = false;

  // Health data types we want to read from Health Connect
  static const List<HealthDataType> _healthDataTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.WORKOUT,
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Health service: Initializing Health Connect...');
      
      // Create Health instance
      _health = Health();
      
      // Configure the health plugin before use
      await _health!.configure();
      debugPrint('Health service: Health plugin configured');
      
      // First, request runtime permissions
      await _requestRuntimePermissions();
      
      // Check if Health Connect is available by trying to request permissions
      try {
        // Try to request permissions to check if Health Connect is available
        bool hasPermissions = await _health!.requestAuthorization(_healthDataTypes);
        _healthConnectAvailable = true; // If we get here without error, Health Connect is available
        debugPrint('Health service: Health Connect available: $_healthConnectAvailable');
        
        if (!hasPermissions) {
          _lastError = 'Health Connect permissions not granted. Please grant permissions in app settings.';
          debugPrint('Health service: $_lastError');
          _isInitialized = true;
          return;
        }
      } catch (e) {
        _healthConnectAvailable = false;
        _lastError = 'Health Connect is not available on this device. Please install Health Connect from Google Play Store.';
        debugPrint('Health service: $_lastError');
        _isInitialized = true;
        return;
      }

      // Test data access to verify everything is working
      debugPrint('Health service: Testing data access...');
      try {
        final testData = await _health!.getHealthDataFromTypes(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now(),
          types: [HealthDataType.HEART_RATE],
        );
        debugPrint('Health service: Test data access successful - found ${testData.length} data points');
      } catch (e) {
        debugPrint('Health service: Test data access failed: $e');
        // Don't fail initialization just because no data is available
      }

      _isInitialized = true;
      _lastError = '';
      debugPrint('Health service: Initialized successfully with Health Connect');
    } catch (e) {
      _lastError = 'Failed to initialize health service: $e';
      debugPrint('Health service: $_lastError');
      _isInitialized = true;
      
      // Automatically run diagnostic when initialization fails
      _runAutomaticDiagnostic();
    }
  }

  /// Request runtime permissions required for health data access
  Future<void> _requestRuntimePermissions() async {
    try {
      debugPrint('Health service: Requesting runtime permissions...');
      
      // Request activity recognition permission
      var activityStatus = await Permission.activityRecognition.request();
      debugPrint('Health service: Activity recognition permission: $activityStatus');
      
      // Request location permissions for workout distance
      var locationStatus = await Permission.location.request();
      debugPrint('Health service: Location permission: $locationStatus');
      
      // Request body sensors permission
      var sensorStatus = await Permission.sensors.request();
      debugPrint('Health service: Body sensors permission: $sensorStatus');
      
    } catch (e) {
      debugPrint('Health service: Error requesting runtime permissions: $e');
    }
  }

  /// Get all health data with comprehensive error handling
  Future<Map<String, dynamic>> getAllHealthData() async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) {
        debugPrint('Health service: Cannot get health data - not initialized');
        return {};
      }
    }

    if (_health == null) {
      debugPrint('Health service: Health instance is null');
      return {};
    }

    try {
      final now = DateTime.now();
      Map<String, dynamic> result = {};

      debugPrint('Health service: Fetching all health data...');

      // First, verify permissions are still valid
      final permissionsValid = await checkAllPermissions();
      if (!permissionsValid) {
        _lastError = 'Permissions are not valid. Please re-grant permissions.';
        debugPrint('Health service: $_lastError');
        return {};
      }

      // Try multiple time ranges to find data, prioritizing recent data
      final timeRanges = [
        {'name': '24 hours', 'duration': const Duration(hours: 24)},
        {'name': '3 days', 'duration': const Duration(days: 3)},
        {'name': '7 days', 'duration': const Duration(days: 7)},
        {'name': '30 days', 'duration': const Duration(days: 30)},
      ];

      bool dataFound = false;
      Map<String, dynamic> bestResult = {};
      
      for (final range in timeRanges) {
        final startTime = now.subtract(range['duration'] as Duration);
        debugPrint('Health service: Trying ${range['name']} range: $startTime to $now');

        try {
          final healthData = await _health!.getHealthDataFromTypes(
            startTime: startTime,
            endTime: now,
            types: _healthDataTypes,
          );

          debugPrint('Health service: Found ${healthData.length} total health data points in ${range['name']} range');

          if (healthData.isNotEmpty) {
            // Process each data type to get the most recent non-zero values
            final rangeResult = <String, dynamic>{};
            _processHealthDataRealTime(healthData, rangeResult);
            
            // Merge results, preferring more recent data
            for (final entry in rangeResult.entries) {
              if (entry.value != null) {
                bestResult[entry.key] = entry.value;
              }
            }
            
            dataFound = true;
            debugPrint('Health service: Successfully processed data from ${range['name']} range');
            
            // If we found meaningful data in the most recent range, use it
            if (range['name'] == '24 hours' && bestResult.isNotEmpty) {
              break;
            }
          }
        } catch (e) {
          debugPrint('Health service: Error fetching data from ${range['name']} range: $e');
          
          // If it's a permission error, update the error message and stop trying
          if (e.toString().contains('permission') || e.toString().contains('denied')) {
            _lastError = 'Health Connect permissions have been revoked. Please re-grant permissions.';
            debugPrint('Health service: Permission error detected: $_lastError');
            return {};
          }
          
          // Continue to next time range if this one failed
          continue;
        }
      }
      
      // Use the best result we found
      result = bestResult;
      
      if (!dataFound) {
        debugPrint('Health service: No health data found in any time range');
      }

      debugPrint('Health service: Final result: $result');
      
      // If no data found, run diagnostic to help troubleshoot
      if (result.isEmpty) {
        debugPrint('Health service: No health data found - running diagnostic...');
        _runAutomaticDiagnostic();
      }
      
      return result;
    } catch (e) {
      _lastError = 'Error getting all health data: $e';
      debugPrint('Health service: $_lastError');
      
      // Automatically run diagnostic when data retrieval fails
      _runAutomaticDiagnostic();
      return {};
    }
  }

  /// Process health data and extract the most recent values for real-time display
  void _processHealthDataRealTime(List<HealthDataPoint> healthData, Map<String, dynamic> result) {
    debugPrint('Health service: Processing ${healthData.length} health data points...');
    
    // Group data by type for easier processing
    final dataByType = <HealthDataType, List<HealthDataPoint>>{};
    for (final data in healthData) {
      dataByType.putIfAbsent(data.type, () => []).add(data);
    }
    
    debugPrint('Health service: Data breakdown by type:');
    dataByType.forEach((type, data) {
      debugPrint('  $type: ${data.length} data points');
    });

    // Process heart rate - get the most recent value (including zero values for debugging)
    final heartRateData = dataByType[HealthDataType.HEART_RATE] ?? [];
    debugPrint('Health service: Found ${heartRateData.length} heart rate data points');
    if (heartRateData.isNotEmpty) {
      heartRateData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      
      // Find the most recent heart rate (including zero values for debugging)
      for (final heartRate in heartRateData) {
        if (heartRate.value is NumericHealthValue) {
          final heartRateValue = (heartRate.value as NumericHealthValue).numericValue;
          debugPrint('Health service: Heart rate value: $heartRateValue (type: ${heartRateValue.runtimeType})');
          // Accept all values including zero for debugging, but validate reasonable ranges
          if (heartRateValue >= 0 && heartRateValue < 300) { // Accept zero values for debugging
            result['heartRate'] = heartRateValue.round();
            result['heartRateTime'] = heartRate.dateFrom;
            debugPrint('Health service: Latest heart rate: ${result['heartRate']} bpm at ${result['heartRateTime']}');
            break;
          } else {
            debugPrint('Health service: Skipping heart rate value $heartRateValue (out of range)');
          }
        } else {
          debugPrint('Health service: Heart rate value is not NumericHealthValue: ${heartRate.value.runtimeType}');
        }
      }
    }

    // Process oxygen saturation - get the most recent value (including zero for debugging)
    final oxygenData = dataByType[HealthDataType.BLOOD_OXYGEN] ?? [];
    debugPrint('Health service: Found ${oxygenData.length} oxygen saturation data points');
    if (oxygenData.isNotEmpty) {
      oxygenData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      
      // Find the most recent oxygen saturation (including zero for debugging)
      for (final oxygen in oxygenData) {
        if (oxygen.value is NumericHealthValue) {
          final oxygenValue = (oxygen.value as NumericHealthValue).numericValue;
          debugPrint('Health service: Oxygen value: $oxygenValue (type: ${oxygenValue.runtimeType})');
          if (oxygenValue >= 0 && oxygenValue <= 100) { // Accept zero values for debugging
            result['oxygenSaturation'] = oxygenValue.round();
            result['oxygenTime'] = oxygen.dateFrom;
            debugPrint('Health service: Latest oxygen saturation: ${result['oxygenSaturation']}% at ${result['oxygenTime']}');
            break;
          } else {
            debugPrint('Health service: Skipping oxygen value $oxygenValue (out of range)');
          }
        } else {
          debugPrint('Health service: Oxygen value is not NumericHealthValue: ${oxygen.value.runtimeType}');
        }
      }
    }

    // Process calories - sum for today (including zero values for debugging)
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final caloriesData = dataByType[HealthDataType.ACTIVE_ENERGY_BURNED] ?? [];
    final todayCaloriesData = caloriesData
        .where((data) => data.dateFrom.isAfter(todayStart))
        .toList();
    debugPrint('Health service: Found ${todayCaloriesData.length} calories data points for today');
    if (todayCaloriesData.isNotEmpty) {
      double totalCalories = 0;
      for (var data in todayCaloriesData) {
        if (data.value is NumericHealthValue) {
          final value = (data.value as NumericHealthValue).numericValue;
          totalCalories += value;
        }
      }
      // Always set calories (including zero for debugging)
      result['calories'] = totalCalories.round();
      result['caloriesTime'] = todayCaloriesData.last.dateFrom; // Use last data point time
      debugPrint('Health service: Today\'s calories: ${result['calories']} kcal');
    }

    // Process sleep - get the most recent sleep session (including zero for debugging)
    final sleepData = dataByType[HealthDataType.SLEEP_IN_BED] ?? [];
    debugPrint('Health service: Found ${sleepData.length} sleep data points');
    if (sleepData.isNotEmpty) {
      sleepData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      
      // Find the most recent sleep data (including zero for debugging)
      for (final sleep in sleepData) {
        if (sleep.value is NumericHealthValue) {
          final sleepValue = (sleep.value as NumericHealthValue).numericValue;
          if (sleepValue >= 0) { // Accept zero values for debugging
            result['sleepHours'] = sleepValue;
            result['sleepTime'] = sleep.dateFrom;
            debugPrint('Health service: Latest sleep: ${result['sleepHours']} hours at ${result['sleepTime']}');
            break;
          }
        }
      }
    }

    // Process steps - get today's total steps (including zero for debugging)
    final stepsData = dataByType[HealthDataType.STEPS] ?? [];
    final todayStepsData = stepsData
        .where((data) => data.dateFrom.isAfter(todayStart))
        .toList();
    debugPrint('Health service: Found ${todayStepsData.length} steps data points for today');
    if (todayStepsData.isNotEmpty) {
      double totalSteps = 0;
      for (var data in todayStepsData) {
        if (data.value is NumericHealthValue) {
          final value = (data.value as NumericHealthValue).numericValue;
          totalSteps += value;
        }
      }
      // Always set steps (including zero for debugging)
      result['steps'] = totalSteps.round();
      debugPrint('Health service: Today\'s steps: ${result['steps']}');
    }

    // Process distance - get today's total distance (including zero for debugging)
    final distanceData = dataByType[HealthDataType.DISTANCE_DELTA] ?? [];
    final todayDistanceData = distanceData
        .where((data) => data.dateFrom.isAfter(todayStart))
        .toList();
    debugPrint('Health service: Found ${todayDistanceData.length} distance data points for today');
    if (todayDistanceData.isNotEmpty) {
      double totalDistance = 0;
      for (var data in todayDistanceData) {
        if (data.value is NumericHealthValue) {
          final value = (data.value as NumericHealthValue).numericValue;
          totalDistance += value;
        }
      }
      // Always set distance (including zero for debugging)
      result['distance'] = totalDistance;
      debugPrint('Health service: Today\'s distance: ${result['distance']} km');
    }

    // Process workouts - get the most recent workout
    final workoutData = dataByType[HealthDataType.WORKOUT] ?? [];
    debugPrint('Health service: Found ${workoutData.length} workout data points');
    if (workoutData.isNotEmpty) {
      workoutData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latestWorkout = workoutData.first;
      result['lastWorkout'] = {
        'type': latestWorkout.value.toString(),
        'time': latestWorkout.dateFrom,
      };
      debugPrint('Health service: Latest workout: ${result['lastWorkout']}');
    }
    
      debugPrint('Health service: Final processed result: $result');
      debugPrint('Health service: Result keys: ${result.keys.toList()}');
      debugPrint('Health service: Result values: ${result.values.toList()}');
      
      // Log which data types we successfully found
      final foundTypes = <String>[];
      if (result['heartRate'] != null) foundTypes.add('Heart Rate');
      if (result['oxygenSaturation'] != null) foundTypes.add('Oxygen Saturation');
      if (result['calories'] != null) foundTypes.add('Calories');
      if (result['sleepHours'] != null) foundTypes.add('Sleep');
      if (result['steps'] != null) foundTypes.add('Steps');
      if (result['distance'] != null) foundTypes.add('Distance');
      debugPrint('Health service: Successfully found data for: ${foundTypes.join(', ')}');
  }

  /// Process health data and extract values (legacy method for backward compatibility)
  void _processHealthData(List<HealthDataPoint> healthData, Map<String, dynamic> result) {
    // Process heart rate
    final heartRateData = healthData
        .where((data) => data.type == HealthDataType.HEART_RATE)
        .toList();
    debugPrint('Health service: Found ${heartRateData.length} heart rate data points');
    if (heartRateData.isNotEmpty && result['heartRate'] == null) {
      heartRateData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latestHeartRate = heartRateData.first;
      if (latestHeartRate.value is NumericHealthValue) {
        result['heartRate'] = (latestHeartRate.value as NumericHealthValue).numericValue.round();
        debugPrint('Health service: Latest heart rate: ${result['heartRate']} bpm');
      }
    }

    // Process oxygen saturation
    final oxygenData = healthData
        .where((data) => data.type == HealthDataType.BLOOD_OXYGEN)
        .toList();
    debugPrint('Health service: Found ${oxygenData.length} oxygen saturation data points');
    if (oxygenData.isNotEmpty && result['oxygenSaturation'] == null) {
      oxygenData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latestOxygen = oxygenData.first;
      if (latestOxygen.value is NumericHealthValue) {
        result['oxygenSaturation'] = (latestOxygen.value as NumericHealthValue).numericValue.round();
        debugPrint('Health service: Latest oxygen saturation: ${result['oxygenSaturation']}%');
      }
    }

    // Process calories (sum for the time period)
    final caloriesData = healthData
        .where((data) => data.type == HealthDataType.ACTIVE_ENERGY_BURNED)
        .toList();
    debugPrint('Health service: Found ${caloriesData.length} calories data points');
    if (caloriesData.isNotEmpty && result['calories'] == null) {
      double totalCalories = 0;
      for (var data in caloriesData) {
        if (data.value is NumericHealthValue) {
          totalCalories += (data.value as NumericHealthValue).numericValue;
        }
      }
      result['calories'] = totalCalories.round();
      debugPrint('Health service: Total calories: ${result['calories']} kcal');
    }

    // Process sleep data (total sleep hours for the period)
    final sleepData = healthData
        .where((data) => data.type == HealthDataType.SLEEP_IN_BED)
        .toList();
    debugPrint('Health service: Found ${sleepData.length} sleep data points');
    if (sleepData.isNotEmpty && result['sleepHours'] == null) {
      // Calculate total sleep hours for the period
      double totalSleepMinutes = 0;
      for (var data in sleepData) {
        if (data.value is NumericHealthValue) {
          totalSleepMinutes += (data.value as NumericHealthValue).numericValue;
        }
      }
      result['sleepHours'] = (totalSleepMinutes / 60.0).roundToDouble();
      debugPrint('Health service: Total sleep hours: ${result['sleepHours']} hours');
    }

    // Process steps data (total steps for the period)
    final stepsData = healthData
        .where((data) => data.type == HealthDataType.STEPS)
        .toList();
    debugPrint('Health service: Found ${stepsData.length} steps data points');
    if (stepsData.isNotEmpty && result['steps'] == null) {
      int totalSteps = 0;
      for (var data in stepsData) {
        if (data.value is NumericHealthValue) {
          totalSteps += (data.value as NumericHealthValue).numericValue.round();
        }
      }
      result['steps'] = totalSteps;
      debugPrint('Health service: Total steps: ${result['steps']} steps');
    }

    // Process distance data (total distance for the period)
    final distanceData = healthData
        .where((data) => data.type == HealthDataType.DISTANCE_DELTA)
        .toList();
    debugPrint('Health service: Found ${distanceData.length} distance data points');
    if (distanceData.isNotEmpty && result['distance'] == null) {
      double totalDistance = 0;
      for (var data in distanceData) {
        if (data.value is NumericHealthValue) {
          totalDistance += (data.value as NumericHealthValue).numericValue;
        }
      }
      result['distance'] = totalDistance.roundToDouble();
      debugPrint('Health service: Total distance: ${result['distance']} km');
    }
  }

  /// Check if we have any health data available
  Future<bool> hasAnyHealthData() async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) return false;
    }

    if (_health == null) return false;

    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final healthData = await _health!.getHealthDataFromTypes(
        startTime: weekAgo,
        endTime: now,
        types: _healthDataTypes,
      );

      debugPrint('Health service: Checking for any health data - found ${healthData.length} data points');
      return healthData.isNotEmpty;
    } catch (e) {
      debugPrint('Health service: Error checking for health data: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  Future<bool> checkAllPermissions() async {
    try {
      debugPrint('Health service: Checking all permissions...');
      
      // Check runtime permissions
      final activityStatus = await Permission.activityRecognition.status;
      final locationStatus = await Permission.location.status;
      final sensorStatus = await Permission.sensors.status;
      
      debugPrint('Health service: Activity recognition: $activityStatus');
      debugPrint('Health service: Location: $locationStatus');
      debugPrint('Health service: Body sensors: $sensorStatus');
      
      final runtimePermissionsGranted = activityStatus.isGranted && 
                                       locationStatus.isGranted && 
                                       sensorStatus.isGranted;
      
      debugPrint('Health service: Runtime permissions granted: $runtimePermissionsGranted');
      
      // Check Health Connect permissions
      if (!_isInitialized) {
        await initialize();
      }
      
      if (!_isInitialized) {
        debugPrint('Health service: Cannot check Health Connect permissions - not initialized');
        return false;
      }
      
      // Verify Health Connect permissions by trying to access data
      if (_health != null && _healthConnectAvailable) {
        try {
          final now = DateTime.now();
          // Try a broader time range and more data types for permission verification
          final testData = await _health!.getHealthDataFromTypes(
            startTime: now.subtract(const Duration(days: 1)),
            endTime: now,
            types: _healthDataTypes,
          );
          debugPrint('Health service: Health Connect permissions verified - can access data (${testData.length} data points)');
          return runtimePermissionsGranted && true;
        } catch (e) {
          debugPrint('Health service: Health Connect permissions verification failed: $e');
          
          // Check if it's a permission error or just no data
          if (e.toString().contains('permission') || 
              e.toString().contains('denied') || 
              e.toString().contains('unauthorized')) {
            _lastError = 'Health Connect permissions may have been revoked. Please re-grant permissions.';
            return false;
          } else {
            // If it's not a permission error, permissions might be OK but no data available
            debugPrint('Health service: Permission check passed but no data available: $e');
            return runtimePermissionsGranted && _healthConnectAvailable;
          }
        }
      }
      
      return runtimePermissionsGranted && _healthConnectAvailable;
    } catch (e) {
      debugPrint('Health service: Error checking permissions: $e');
      return false;
    }
  }

  /// Helper method to find the most recent non-zero value from a sorted list of health data
  T? _findLatestNonZeroValue<T extends num>(List<HealthDataPoint> dataPoints, T Function(NumericHealthValue) extractor) {
    for (final data in dataPoints) {
      if (data.value is NumericHealthValue) {
        final value = extractor(data.value as NumericHealthValue);
        if (value > 0) {
          return value;
        }
      }
    }
    return null;
  }

  /// Get detailed debug information about health data processing
  Future<Map<String, dynamic>> getDebugInfo() async {
    Map<String, dynamic> debugInfo = {
      'isInitialized': _isInitialized,
      'healthConnectAvailable': _healthConnectAvailable,
      'lastError': _lastError,
      'healthInstance': _health != null,
    };
    
    if (_isInitialized && _health != null) {
      try {
        final now = DateTime.now();
        final healthData = await _health!.getHealthDataFromTypes(
          startTime: now.subtract(const Duration(hours: 24)),
          endTime: now,
          types: _healthDataTypes,
        );
        
        debugInfo['rawDataPoints'] = healthData.length;
        debugInfo['dataTypes'] = healthData.map((d) => d.type.toString()).toSet().toList();
        
        // Process the data to see what we get
        final result = <String, dynamic>{};
        _processHealthDataRealTime(healthData, result);
        debugInfo['processedData'] = result;
        
        // Add detailed data analysis
        debugInfo['dataAnalysis'] = {
          'totalDataPoints': healthData.length,
          'dataByType': _groupDataByType(healthData),
          'valueRanges': _analyzeValueRanges(healthData),
          'timeRanges': _analyzeTimeRanges(healthData),
        };
        
      } catch (e) {
        debugInfo['processingError'] = e.toString();
      }
    }
    
    return debugInfo;
  }

  /// Group data by type for analysis
  Map<String, int> _groupDataByType(List<HealthDataPoint> healthData) {
    final dataByType = <String, int>{};
    for (final data in healthData) {
      final type = data.type.toString();
      dataByType[type] = (dataByType[type] ?? 0) + 1;
    }
    return dataByType;
  }

  /// Analyze value ranges in the data
  Map<String, dynamic> _analyzeValueRanges(List<HealthDataPoint> healthData) {
    final analysis = <String, dynamic>{};
    
    for (final data in healthData) {
      if (data.value is NumericHealthValue) {
        final type = data.type.toString();
        final value = (data.value as NumericHealthValue).numericValue;
        
        if (!analysis.containsKey(type)) {
          analysis[type] = {
            'min': value,
            'max': value,
            'count': 0,
            'zeroCount': 0,
            'values': <double>[],
          };
        }
        
        final typeAnalysis = analysis[type] as Map<String, dynamic>;
        typeAnalysis['min'] = math.min(typeAnalysis['min'] as double, value);
        typeAnalysis['max'] = math.max(typeAnalysis['max'] as double, value);
        typeAnalysis['count'] = (typeAnalysis['count'] as int) + 1;
        if (value == 0) {
          typeAnalysis['zeroCount'] = (typeAnalysis['zeroCount'] as int) + 1;
        }
        (typeAnalysis['values'] as List<double>).add(value.toDouble());
      }
    }
    
    return analysis;
  }

  /// Analyze time ranges in the data
  Map<String, dynamic> _analyzeTimeRanges(List<HealthDataPoint> healthData) {
    if (healthData.isEmpty) return {'error': 'No data to analyze'};
    
    final sortedData = List<HealthDataPoint>.from(healthData);
    sortedData.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    
    final earliest = sortedData.first.dateFrom;
    final latest = sortedData.last.dateFrom;
    final now = DateTime.now();
    
    return {
      'earliest': earliest.toString(),
      'latest': latest.toString(),
      'timeSpan': latest.difference(earliest).inHours.toString() + ' hours',
      'hoursAgoEarliest': now.difference(earliest).inHours,
      'hoursAgoLatest': now.difference(latest).inHours,
    };
  }

  /// Get specific health data point
  Future<HealthDataPoint?> getLatestHeartRate() async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized || _health == null) {
        debugPrint('Health service: Cannot get heart rate - not initialized');
        return null;
      }
    }

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      debugPrint('Health service: Fetching heart rate data from $yesterday to $now');

      final healthData = await _health!.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      debugPrint('Health service: Found ${healthData.length} heart rate data points');

      if (healthData.isNotEmpty) {
        // Sort by date and get the latest
        healthData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        final latest = healthData.first;
        debugPrint('Health service: Latest heart rate: ${latest.value} at ${latest.dateFrom}');
        return latest;
      } else {
        debugPrint('Health service: No heart rate data found in the last 24 hours');
      }
    } catch (e) {
      _lastError = 'Error getting heart rate data: $e';
      debugPrint('Health service: $_lastError');
    }
    return null;
  }

  bool get isInitialized => _isInitialized;
  String get lastError => _lastError;
  bool get healthConnectAvailable => _healthConnectAvailable;

  Future<bool> isHealthDataAvailable() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return _isInitialized && _lastError.isEmpty && _healthConnectAvailable;
    } catch (e) {
      _lastError = 'Error checking health data availability: $e';
      debugPrint('Health service: $_lastError');
      return false;
    }
  }

  /// Get user-friendly error message with actionable steps
  String getUserFriendlyErrorMessage() {
    if (_lastError.isEmpty) return '';
    
    if (_lastError.contains('not available')) {
      return 'Health Connect is not installed. Please install it from Google Play Store and try again.';
    } else if (_lastError.contains('permissions not granted') || _lastError.contains('permissions are not valid')) {
      return 'Please grant health permissions in your device settings: Settings > Apps > CardioPTech > Permissions';
    } else if (_lastError.contains('permissions have been revoked')) {
      return 'Health Connect permissions have been revoked. Please re-grant permissions in your device settings.';
    } else if (_lastError.contains('No data') || _lastError.contains('not found')) {
      return 'No health data found. Make sure your fitness tracker is connected and syncing with Health Connect.';
    } else if (_lastError.contains('Failed to initialize')) {
      return 'Unable to initialize Health Connect. Please check if Health Connect is installed and try again.';
    } else {
      return 'Unable to access health data. Please check your Health Connect settings and try again.';
    }
  }

  /// Get comprehensive health data status for user feedback
  Future<Map<String, dynamic>> getHealthDataStatus() async {
    Map<String, dynamic> status = {
      'isConnected': false,
      'hasData': false,
      'dataTypes': <String>[],
      'lastUpdate': null,
      'issues': <String>[],
      'recommendations': <String>[],
    };

    try {
      // Check if Health Connect is available and initialized
      if (!_isInitialized) {
        await initialize();
      }

      if (!_isInitialized || !_healthConnectAvailable) {
        status['issues'].add('Health Connect is not available or not initialized');
        status['recommendations'].add('Install Health Connect from Google Play Store');
        return status;
      }

      status['isConnected'] = true;

      // Check permissions
      final permissionsGranted = await checkAllPermissions();
      if (!permissionsGranted) {
        status['issues'].add('Health permissions not granted');
        status['recommendations'].add('Grant health permissions in device settings');
        return status;
      }

      // Try to get data
      final now = DateTime.now();
      final healthData = await _health!.getHealthDataFromTypes(
        startTime: now.subtract(const Duration(days: 7)),
        endTime: now,
        types: _healthDataTypes,
      );

      if (healthData.isEmpty) {
        status['issues'].add('No health data found in the last 7 days');
        status['recommendations'].addAll([
          'Connect your fitness tracker to Health Connect',
          'Make sure your fitness tracker is syncing data',
          'Try recording some health data manually in Health Connect',
        ]);
        return status;
      }

      status['hasData'] = true;

      // Analyze what data types we have
      final dataByType = <String, int>{};
      DateTime? latestUpdate;
      
      for (final data in healthData) {
        final type = data.type.toString();
        dataByType[type] = (dataByType[type] ?? 0) + 1;
        
        if (latestUpdate == null || data.dateFrom.isAfter(latestUpdate)) {
          latestUpdate = data.dateFrom;
        }
      }

      status['dataTypes'] = dataByType.keys.toList();
      status['lastUpdate'] = latestUpdate?.toString();

      // Check for zero values (might indicate sync issues)
      final zeroValueTypes = <String>[];
      for (final data in healthData) {
        if (data.value is NumericHealthValue) {
          final value = (data.value as NumericHealthValue).numericValue;
          if (value == 0) {
            final type = data.type.toString();
            if (!zeroValueTypes.contains(type)) {
              zeroValueTypes.add(type);
            }
          }
        }
      }

      if (zeroValueTypes.isNotEmpty) {
        status['issues'].add('Some data types show zero values: ${zeroValueTypes.join(', ')}');
        status['recommendations'].add('Check if your fitness tracker is recording data properly');
      }

      // Check data freshness
      if (latestUpdate != null) {
        final hoursAgo = now.difference(latestUpdate).inHours;
        if (hoursAgo > 24) {
          status['issues'].add('Health data is ${hoursAgo} hours old');
          status['recommendations'].add('Sync your fitness tracker or record new data');
        }
      }

    } catch (e) {
      status['issues'].add('Error checking health data: $e');
      status['recommendations'].add('Try restarting the app or reconnecting to Health Connect');
    }

    return status;
  }

  /// Debug method to get raw health data for troubleshooting
  Future<Map<String, dynamic>> getRawHealthDataForDebugging() async {
    Map<String, dynamic> debugInfo = {
      'isInitialized': _isInitialized,
      'healthConnectAvailable': _healthConnectAvailable,
      'lastError': _lastError,
      'rawData': [],
      'processedData': {},
    };

    if (!_isInitialized) {
      await initialize();
    }

    if (_health == null) {
      debugInfo['error'] = 'Health instance is null';
      return debugInfo;
    }

    try {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 7));
      
      final healthData = await _health!.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: _healthDataTypes,
      );

      debugInfo['rawData'] = healthData.map((data) => {
        'type': data.type.toString(),
        'value': data.value.toString(),
        'valueType': data.value.runtimeType.toString(),
        'dateFrom': data.dateFrom.toString(),
        'dateTo': data.dateTo.toString(),
        'sourceName': data.sourceName,
        'sourceId': data.sourceId,
        'isNumeric': data.value is NumericHealthValue,
        'numericValue': data.value is NumericHealthValue ? (data.value as NumericHealthValue).numericValue : null,
      }).toList();

      // Process the data
      _processHealthDataRealTime(healthData, debugInfo['processedData']);

    } catch (e) {
      debugInfo['error'] = e.toString();
    }

    return debugInfo;
  }

  // Method to reset the service (useful for debugging)
  void reset() {
    _isInitialized = false;
    _lastError = '';
    _healthConnectAvailable = false;
    _health = null;
    debugPrint('Health service: Reset');
  }

  /// Re-request all permissions (useful when permissions are denied)
  Future<bool> requestPermissions() async {
    try {
      debugPrint('Health service: Re-requesting all permissions...');
      
      // Reset the service state
      reset();
      
      // Request runtime permissions first
      await _requestRuntimePermissions();
      
      // Re-initialize Health Connect
      await initialize();
      
      // Check if permissions are now granted
      final permissionsGranted = await checkAllPermissions();
      
      if (permissionsGranted) {
        debugPrint('Health service: All permissions granted successfully');
        return true;
      } else {
        debugPrint('Health service: Some permissions still not granted');
        return false;
      }
    } catch (e) {
      debugPrint('Health service: Error requesting permissions: $e');
      _lastError = 'Failed to request permissions: $e';
      return false;
    }
  }

  /// Automatically run diagnostic when there are issues
  Future<void> _runAutomaticDiagnostic() async {
    try {
      debugPrint('=== AUTOMATIC HEALTH CONNECT DIAGNOSTIC ===');
      debugPrint('Running diagnostic due to initialization failure...');
      
      final diagnostic = await runDiagnostic();
      
      debugPrint('=== AUTOMATIC DIAGNOSTIC RESULTS ===');
      debugPrint('Health Connect Available: ${diagnostic['healthConnectAvailable']}');
      debugPrint('Runtime Permissions: ${diagnostic['runtimePermissions']}');
      debugPrint('Health Connect Permissions: ${diagnostic['healthConnectPermissions']}');
      debugPrint('Data Available: ${diagnostic['dataAvailable']}');
      debugPrint('Data Points Found: ${diagnostic['dataPointsFound']}');
      
      if (diagnostic['dataBreakdown'] != null) {
        debugPrint('Data Breakdown:');
        (diagnostic['dataBreakdown'] as Map).forEach((key, value) {
          debugPrint('  $key: $value data points');
        });
      }
      
      if (diagnostic['errors'].isNotEmpty) {
        debugPrint('Errors found:');
        for (String error in diagnostic['errors']) {
          debugPrint('  - $error');
        }
      }
      
      if (diagnostic['success']) {
        debugPrint(' Health Connect integration is working correctly!');
      } else {
        debugPrint(' Health Connect integration has issues - check errors above');
      }
      
      debugPrint('=== AUTOMATIC DIAGNOSTIC COMPLETE ===');
    } catch (e) {
      debugPrint(' Error during automatic diagnostic: $e');
    }
  }

  /// Comprehensive diagnostic method
  Future<Map<String, dynamic>> runDiagnostic() async {
    Map<String, dynamic> diagnostic = {
      'healthConnectAvailable': false,
      'runtimePermissions': {},
      'healthConnectPermissions': false,
      'dataAvailable': false,
      'dataPointsFound': 0,
      'dataBreakdown': {},
      'errors': [],
      'success': false,
    };

    try {
      debugPrint('=== HEALTH CONNECT DIAGNOSTIC ===');
      
      // 1. Check Health Connect availability
      debugPrint('1. Checking Health Connect availability...');
      _health = Health();
      await _health!.configure();
      
      // Try to request permissions to check if Health Connect is available
      try {
        bool hasPermissions = await _health!.requestAuthorization(_healthDataTypes);
        diagnostic['healthConnectAvailable'] = true;
        debugPrint('Health Connect available: ${diagnostic['healthConnectAvailable']}');
        
        if (!hasPermissions) {
          diagnostic['errors'].add('Health Connect permissions not granted');
          return diagnostic;
        }
      } catch (e) {
        diagnostic['healthConnectAvailable'] = false;
        diagnostic['errors'].add('Health Connect is not available on this device: $e');
        debugPrint('Health Connect not available: $e');
        return diagnostic;
      }
      
      // 2. Check runtime permissions
      debugPrint('2. Checking runtime permissions...');
      final activityStatus = await Permission.activityRecognition.status;
      final locationStatus = await Permission.location.status;
      final sensorStatus = await Permission.sensors.status;
      
      diagnostic['runtimePermissions'] = {
        'activityRecognition': activityStatus.toString(),
        'location': locationStatus.toString(),
        'bodySensors': sensorStatus.toString(),
      };
      
      final allRuntimePermissionsGranted = activityStatus.isGranted && 
                                         locationStatus.isGranted && 
                                         sensorStatus.isGranted;
      
      debugPrint('All runtime permissions granted: $allRuntimePermissionsGranted');
      
      if (!allRuntimePermissionsGranted) {
        diagnostic['errors'].add('Some runtime permissions are not granted');
        return diagnostic;
      }
      
      // 3. Health Connect permissions already checked above
      debugPrint('3. Health Connect permissions already verified');
      diagnostic['healthConnectPermissions'] = true;
      
      // 4. Check for data across multiple time ranges
      debugPrint('4. Checking for health data across multiple time ranges...');
      final now = DateTime.now();
      final timeRanges = [
        {'name': '24 hours', 'duration': const Duration(hours: 24)},
        {'name': '3 days', 'duration': const Duration(days: 3)},
        {'name': '7 days', 'duration': const Duration(days: 7)},
        {'name': '30 days', 'duration': const Duration(days: 30)},
      ];
      
      List<HealthDataPoint> allHealthData = [];
      
      for (final range in timeRanges) {
        final startTime = now.subtract(range['duration'] as Duration);
        debugPrint('Checking ${range['name']} range: $startTime to $now');
        
        try {
          final healthData = await _health!.getHealthDataFromTypes(
            startTime: startTime,
            endTime: now,
            types: _healthDataTypes,
          );
          
          debugPrint('Found ${healthData.length} data points in ${range['name']} range');
          
          if (healthData.isNotEmpty) {
            allHealthData = healthData;
            diagnostic['dataAvailable'] = true;
            diagnostic['dataPointsFound'] = healthData.length;
            diagnostic['dataFoundInRange'] = range['name'];
            debugPrint('Data found in ${range['name']} range');
            break;
          }
        } catch (e) {
          debugPrint('Error checking ${range['name']} range: $e');
          continue;
        }
      }
      
      if (allHealthData.isNotEmpty) {
        // Group data by type
        final dataByType = <HealthDataType, List<HealthDataPoint>>{};
        for (final data in allHealthData) {
          dataByType.putIfAbsent(data.type, () => []).add(data);
        }
        
        diagnostic['dataBreakdown'] = {};
        for (final entry in dataByType.entries) {
          diagnostic['dataBreakdown'][entry.key.toString()] = entry.value.length;
        }
        
        // Test data processing
        debugPrint('5. Testing data processing...');
        final testResult = <String, dynamic>{};
        _processHealthDataRealTime(allHealthData, testResult);
        diagnostic['processedData'] = testResult;
        debugPrint('Processed data: $testResult');
      } else {
        diagnostic['errors'].add('No health data found in any time range');
      }
      
      diagnostic['success'] = diagnostic['dataAvailable'] && diagnostic['healthConnectAvailable'] && diagnostic['healthConnectPermissions'];
      
      if (diagnostic['success']) {
        debugPrint(' Health Connect integration is working correctly!');
      } else {
        debugPrint(' Health Connect integration has issues');
      }
      
    } catch (e) {
      diagnostic['errors'].add('Error during diagnostic: $e');
      debugPrint(' Error during diagnostic: $e');
    }
    
    debugPrint('=== DIAGNOSTIC COMPLETE ===');
    return diagnostic;
  }
}
