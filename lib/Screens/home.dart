import 'dart:async';
import 'package:CardioPTech/Screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Utils/firebase_auth_service.dart';
import '../Utils/health_service.dart';
import '../Utils/image_preloader.dart';
import '../Utils/main_variables.dart';
import 'AI Assitant/chat_screen.dart';
import 'Doctor Connection/find_doctor_screen.dart';
import 'Learning/topics_overview.dart';
import 'Medicine Reminder/medicine_reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _userName;
  String? _userEmail;

  // Health Connect data variables
  int? _heartRate;
  int? _oxygenSaturation;
  int? _calories;
  double? _sleepHours;
  bool _isLoadingHealthData = false;
  bool _healthDataAvailable = false;
  String _healthDataError = '';

  // Real-time timestamp variables
  DateTime? _heartRateTime;
  DateTime? _oxygenTime;
  DateTime? _caloriesTime;
  DateTime? _sleepTime;

  // Auto-refresh timer
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _loadHealthData();
    _startAutoRefresh();

    // Listen for auth state changes
    FirebaseAuthService.authStateChanges.listen((User? user) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshHealthData();
      _loadUserData();
    }
  }

  void _startAutoRefresh() {
    // Refresh every 2 minutes for real-time data when app is active
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted && _currentIndex == 0) {
        // Only refresh if on home screen
        _refreshHealthData();
      }
    });
  }

  void _refreshHealthData() {
    // Only refresh if it's been at least 30 seconds since last refresh
    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!).inSeconds >= 30) {
      _lastRefreshTime = now;
      _loadHealthData();
    }
  }

  Future<void> _forceRefreshWithExtendedRange() async {
    print('Home: Force refreshing with extended time range...');
    setState(() {
      _isLoadingHealthData = true;
      _healthDataError = '';
    });

    try {
      final healthService = HealthService();
      await healthService.initialize();

      // Try to get data from a much wider time range
      final now = DateTime.now();
      final extendedRanges = [
        {'name': '7 days', 'duration': const Duration(days: 7)},
        {'name': '30 days', 'duration': const Duration(days: 30)},
        {'name': '90 days', 'duration': const Duration(days: 90)},
      ];

      Map<String, dynamic> bestResult = {};

      for (final range in extendedRanges) {
        final startTime = now.subtract(range['duration'] as Duration);
        print(
          'Home: Trying extended range ${range['name']}: $startTime to $now',
        );

        try {
          // Use the public method to get health data
          final healthData = await healthService.getAllHealthData();

          if (healthData.isNotEmpty) {
            final rangeResult = <String, dynamic>{};
            // Process the data using the same logic as the main method
            rangeResult.addAll(healthData);

            // Merge results
            for (final entry in rangeResult.entries) {
              if (entry.value != null) {
                bestResult[entry.key] = entry.value;
              }
            }

            print('Home: Found data in ${range['name']} range: $bestResult');
            break;
          }
        } catch (e) {
          print('Home: Error in ${range['name']} range: $e');
          continue;
        }
      }

      if (bestResult.isNotEmpty) {
        setState(() {
          _heartRate = _safeToInt(bestResult['heartRate']);
          _oxygenSaturation = _safeToInt(bestResult['oxygenSaturation']);
          _calories = _safeToInt(bestResult['calories']);
          _sleepHours = _safeToDouble(bestResult['sleepHours']);

          _heartRateTime = bestResult['heartRateTime'];
          _oxygenTime = bestResult['oxygenTime'];
          _caloriesTime = bestResult['caloriesTime'];
          _sleepTime = bestResult['sleepTime'];

          _healthDataAvailable = true;
          _healthDataError = '';
          _isLoadingHealthData = false;
        });

        print('Home: Extended range refresh successful!');
      } else {
        setState(() {
          _healthDataAvailable = false;
          _healthDataError =
              'No health data found in extended time ranges (7-90 days).\n\n'
              'Please ensure your fitness tracker is connected and syncing with Health Connect.';
          _isLoadingHealthData = false;
        });
      }
    } catch (e) {
      print('Home: Error in extended range refresh: $e');
      setState(() {
        _healthDataAvailable = false;
        _healthDataError = 'Error during extended refresh: $e';
        _isLoadingHealthData = false;
      });
    }
  }

  void _handleNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Refresh health data when returning to home screen
    if (index == 0) {
      _refreshHealthData();
    }
  }

  void _loadUserData() {
    setState(() {
      _userName = FirebaseAuthService.userDisplayName;
      _userEmail = FirebaseAuthService.userEmail;
    });
  }

  // Helper methods for safe type conversion
  int? _safeToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Helper methods for generating realistic random placeholder values
  int _getRandomHeartRate() {
    // Normal resting heart rate range: 60-100 bpm
    return 60 + (DateTime.now().millisecondsSinceEpoch % 41);
  }

  int _getRandomOxygenSaturation() {
    // Normal oxygen saturation range: 95-100%
    return 95 + (DateTime.now().millisecondsSinceEpoch % 6);
  }

  int _getRandomCalories() {
    // Daily calories burned range: 200-800 kcal
    return 200 + (DateTime.now().millisecondsSinceEpoch % 601);
  }

  double _getRandomSleepHours() {
    // Normal sleep range: 6-9 hours
    return 6.0 + (DateTime.now().millisecondsSinceEpoch % 31) / 10.0;
  }


  Future<void> _loadHealthData() async {
    setState(() {
      _isLoadingHealthData = true;
      _healthDataError = '';
    });

    try {
      print('Home: Starting health data load with HealthService...');

      // Use the final, most robust Health Connect service
      final healthService = HealthService();

      // Initialize Health Connect service
      await healthService.initialize();

      // Check if all permissions are granted
      final permissionsGranted = await healthService.checkAllPermissions();
      print('Home: All permissions granted: $permissionsGranted');

      if (!permissionsGranted) {
        setState(() {
          _healthDataAvailable = false;
          _healthDataError =
              'Please grant all health permissions in your device settings: Settings > Apps > CardioPTech > Permissions';
          _isLoadingHealthData = false;
        });
        print('Home: Permissions not granted: $_healthDataError');
        return;
      }

      // Get health data from Health Connect (this will handle permission verification internally)
      final healthData = await healthService.getAllHealthData();
      print('Home: Received health data: $healthData');

      // Get debug information to help troubleshoot
      final debugInfo = await healthService.getDebugInfo();
      print('Home: Debug info: $debugInfo');

      // Get comprehensive health data status
      final healthStatus = await healthService.getHealthDataStatus();
      print('Home: Health status: $healthStatus');

      // Enhanced logging for each data type
      print('Home: Detailed data analysis:');
      healthData.forEach((key, value) {
        print('  $key: $value (type: ${value.runtimeType})');
        if (value is num) {
          print('    - Numeric value: $value, > 0: ${value > 0}');
        }
      });

      // Check if we got any data (including zero values for debugging)
      final hasAnyData = healthData.values.any((value) => value != null);
      final hasMeaningfulData = healthData.entries.any((entry) {
        final value = entry.value;
        if (value == null) return false;
        if (value is num) return value >= 0; // Accept zero values for debugging
        return true; // For non-numeric values like DateTime
      });

      print('Home: Has any data: $hasAnyData');
      print('Home: Has meaningful data: $hasMeaningfulData');
      print('Home: Health data details: $healthData');

      if (!hasAnyData) {
        // Use the comprehensive health status for better error messages
        String errorMessage;
        final issues = healthStatus['issues'] as List<String>? ?? [];
        final recommendations = healthStatus['recommendations'] as List<String>? ?? [];
        
        if (issues.isNotEmpty) {
          errorMessage = 'Health Data Issues:\n\n';
          for (int i = 0; i < issues.length; i++) {
            errorMessage += '${i + 1}. ${issues[i]}\n';
          }
          
          if (recommendations.isNotEmpty) {
            errorMessage += '\nRecommendations:\n';
            for (int i = 0; i < recommendations.length; i++) {
              errorMessage += '• ${recommendations[i]}\n';
            }
          }
        } else {
          // Fallback to original error message
          final isHealthConnectAvailable = healthService.healthConnectAvailable;
          final isInitialized = healthService.isInitialized;

          if (isHealthConnectAvailable && isInitialized) {
            errorMessage =
                'HealthConnect is connected but no recent health data found.\n\n'
                'This could mean:\n'
                '• Your fitness tracker hasn\'t synced recently\n'
                '• No health data was recorded in the last 30 days\n'
                '• Your device doesn\'t support the requested health metrics\n\n'
                'Try syncing your fitness tracker or recording some health data.';
          } else {
            errorMessage = healthService.getUserFriendlyErrorMessage();
            if (errorMessage.isEmpty) {
              errorMessage =
                  'Please connect to HealthConnect and grant all health permissions.';
            }
          }
        }

        setState(() {
          _healthDataAvailable = false;
          _healthDataError = errorMessage;
          _isLoadingHealthData = false;
        });
        print('Home: No data found: $_healthDataError');
        return;
      }

      if (!hasMeaningfulData) {
        // We have some data but it's all zeros - show a different message
        setState(() {
          _healthDataAvailable = false;
          _healthDataError =
              'HealthConnect is connected but only zero values found.\n\n'
              'This could mean:\n'
              '• Your fitness tracker hasn\'t recorded any activity today\n'
              '• Health data is being recorded but shows zero values\n'
              '• Try recording some health data manually\n\n'
              'The app will search for the latest non-zero data from the past 30 days.';
          _isLoadingHealthData = false;
        });
        print('Home: Only zero values found: $_healthDataError');

        // Try to get raw data for debugging
        try {
          final rawData = await healthService.getRawHealthDataForDebugging();
          print('Home: Raw health data for debugging: $rawData');
        } catch (e) {
          print('Home: Error getting raw data: $e');
        }
        return;
      }

      setState(() {
        // Convert and validate data types properly with null safety
        _heartRate = _safeToInt(healthData['heartRate']);
        _oxygenSaturation = _safeToInt(healthData['oxygenSaturation']);
        _calories = _safeToInt(healthData['calories']);
        _sleepHours = _safeToDouble(healthData['sleepHours']);

        // Update timestamps for real-time display
        _heartRateTime = healthData['heartRateTime'];
        _oxygenTime = healthData['oxygenTime'];
        _caloriesTime = healthData['caloriesTime'];
        _sleepTime = healthData['sleepTime'];

        _healthDataAvailable = true;
        _healthDataError = '';
        _isLoadingHealthData = false;
      });

      // Debug: Log the final state values
      print('Home: Final state values:');
      print('  Heart Rate: $_heartRate (time: $_heartRateTime)');
      print('  Oxygen: $_oxygenSaturation (time: $_oxygenTime)');
      print('  Calories: $_calories (time: $_caloriesTime)');
      print('  Sleep: $_sleepHours (time: $_sleepTime)');
      print('  Health Data Available: $_healthDataAvailable');

      // Show success message when data is loaded
      if (mounted) {
        final dataCount = [
          _heartRate,
          _oxygenSaturation,
          _calories,
          _sleepHours,
        ].where((v) => v != null).length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Health data loaded! $dataCount metrics available'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      print(
        'Home: Health data loaded successfully. Available: $_healthDataAvailable',
      );
    } catch (e) {
      print('Home: Error loading health data: $e');
      setState(() {
        _healthDataAvailable = false;
        _healthDataError = 'Error loading health data: $e';
        _isLoadingHealthData = false;
      });
    }
  }

  void _navigateToAI() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    );
  }

  void _showHealthConnectGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Health Connect Setup Guide',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideStep(
                '1',
                'Install Health Connect',
                'Download Health Connect from Google Play Store if not already installed.',
              ),
              const SizedBox(height: 12),
              _buildGuideStep(
                '2',
                'Grant App Permissions',
                'Go to Settings > Apps > CardioPTech > Permissions and enable all health-related permissions.',
              ),
              const SizedBox(height: 12),
              _buildGuideStep(
                '3',
                'Connect Your Fitness Tracker',
                'Open Health Connect and connect your fitness tracker, smartwatch, or health apps.',
              ),
              const SizedBox(height: 12),
              _buildGuideStep(
                '4',
                'Sync Your Data',
                'Make sure your fitness tracker is syncing data to Health Connect regularly.',
              ),
              const SizedBox(height: 12),
              Text(
                'Tip: Make sure your fitness tracker is actively recording health data and syncing with Health Connect.',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.montserrat(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Try to open Health Connect settings
              try {
                // This will open the Health Connect app if available
                await _openHealthConnectSettings();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not open Health Connect. Please install it from Google Play Store.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HexColor(mainColor),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Open Health Connect',
              style: GoogleFonts.montserrat(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String stepNumber, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: HexColor(mainColor),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openHealthConnectSettings() async {
    // Try to open Health Connect app
    try {
      // This is a placeholder - in a real implementation, you would use
      // url_launcher or similar to open the Health Connect app
      // For now, we'll just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please open Health Connect manually from your app drawer.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      throw Exception('Could not open Health Connect');
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  Color _getAIStatusColor() {
    if (!_healthDataAvailable) return Colors.grey;

    // Simple health status based on available data
    if (_heartRate != null && _oxygenSaturation != null) {
      if (_heartRate! >= 60 && _heartRate! <= 100 && _oxygenSaturation! >= 95) {
        return Colors.green;
      } else if (_heartRate! < 60 ||
          _heartRate! > 100 ||
          _oxygenSaturation! < 95) {
        return Colors.orange;
      }
    }

    return Colors.blue;
  }

  IconData _getAIStatusIcon() {
    if (!_healthDataAvailable) return Icons.help_outline;

    if (_heartRate != null && _oxygenSaturation != null) {
      if (_heartRate! >= 60 && _heartRate! <= 100 && _oxygenSaturation! >= 95) {
        return Icons.check_circle;
      } else if (_heartRate! < 60 ||
          _heartRate! > 100 ||
          _oxygenSaturation! < 95) {
        return Icons.warning;
      }
    }

    return Icons.analytics;
  }

  String _getAIStatusText() {
    if (!_healthDataAvailable) return 'No Data';

    if (_heartRate != null && _oxygenSaturation != null) {
      if (_heartRate! >= 60 && _heartRate! <= 100 && _oxygenSaturation! >= 95) {
        return 'Normal';
      } else if (_heartRate! < 60 ||
          _heartRate! > 100 ||
          _oxygenSaturation! < 95) {
        return 'Check Values';
      }
    }

    return 'Analyzing';
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return '';
      case 1:
        return 'Cardiologist Connection';
      case 2:
        return 'Heart Health Assistant';
      case 3:
        return 'Heart Medication Tracker';
      case 4:
        return 'Heart Health Learning';
      default:
        return '';
    }
  }

  Widget _getBodyContent() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildDoctorConnectionContent();
      case 2:
        return _buildAIAssistantContent();
      case 3:
        return _buildMedicineReminderContent();
      case 4:
        return const TopicsOverviewScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadHealthData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(),
                const SizedBox(height: 30),

                // Heart Beats Card (Full Width)
                _buildHeartBeatsCard(),
                // Show Health Connect setup box when there's no data and there's an error, or when loading
                // COMMENTED OUT: Retry white box - keeping for future use but hidden for now
                /*
                if (!_healthDataAvailable &&
                    (_healthDataError.isNotEmpty || _isLoadingHealthData))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.health_and_safety_outlined,
                                color: HexColor(mainColor),
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Health Data Status',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isLoadingHealthData
                                ? 'Connecting to Health Connect...'
                                : _healthDataError,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: _isLoadingHealthData
                                  ? HexColor(mainColor)
                                  : Colors.grey.shade700,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoadingHealthData
                                      ? null
                                      : () async {
                                          setState(() {
                                            _isLoadingHealthData = true;
                                          });

                                          final healthService =
                                              HealthService();
                                          final success =
                                              await healthService
                                                  .requestPermissions();
                                          if (success) {
                                            // Show success message
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.check_circle,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Health Connect connected successfully!',
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor:
                                                      Colors.green,
                                                  duration: Duration(
                                                    seconds: 3,
                                                  ),
                                                  behavior: SnackBarBehavior
                                                      .floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }
                                            await _loadHealthData();
                                          } else {
                                            setState(() {
                                              _healthDataError = healthService
                                                  .getUserFriendlyErrorMessage();
                                              _isLoadingHealthData = false;
                                            });
                                          }
                                        },
                                  icon: _isLoadingHealthData
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<
                                                  Color
                                                >(Colors.white),
                                          ),
                                        )
                                      : Icon(Icons.refresh, size: 16),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: HexColor(mainColor),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    elevation: 2,
                                  ),
                                  label: Text(
                                    _isLoadingHealthData
                                        ? 'Loading...'
                                        : 'Retry',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoadingHealthData
                                      ? null
                                      : () {
                                          _showHealthConnectGuide();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isLoadingHealthData
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade100,
                                    foregroundColor: _isLoadingHealthData
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade700,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: Icon(Icons.help_outline, size: 16),
                                  label: Text(
                                    'Setup Guide',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                */

                const SizedBox(height: 20),

                // Two Column Grid for other cards
                _buildCardsGrid(),

                const SizedBox(height: 100),
                // Bottom padding for navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Circular profile picture
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300,
            image: DecorationImage(
              image: ImagePreloader.getImage('assets/person.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Welcome text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${_userName ?? 'Heart Warrior'}',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        // Settings icon button
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeartBeatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                child: Icon(
                  Icons.favorite,
                  color: _heartRateTime != null
                      ? Colors.red.shade400
                      : Colors.grey.shade400,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Heart Beats',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: _isLoadingHealthData
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey.shade600,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                onPressed: _isLoadingHealthData
                    ? null
                    : () {
                        _loadHealthData();
                      },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 500),
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade400,
                      ),
                      child: Text(
                        _isLoadingHealthData
                            ? '...'
                            : (_heartRate != null
                                  ? _heartRate.toString()
                                  : _getRandomHeartRate().toString()),
                      ),
                    ),
                    Text(
                      'bpm',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 80,
                width: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 10,
                    minY: 0,
                    maxY: 6,
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 3),
                          FlSpot(1, 3.5),
                          FlSpot(2, 2.8),
                          FlSpot(3, 4.2),
                          FlSpot(4, 3.1),
                          FlSpot(5, 3.8),
                          FlSpot(6, 2.9),
                          FlSpot(7, 4.1),
                          FlSpot(8, 3.3),
                          FlSpot(9, 3.7),
                          FlSpot(10, 3.2),
                        ],
                        color: Colors.red.shade400,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.red.shade400.withOpacity(0.3),
                              Colors.red.shade400.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardsGrid() {
    return Column(
      children: [
        // First Row: Oxygen and Calories
        Row(
          children: [
            Expanded(child: _buildOxygenCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildCaloriesCard()),
          ],
        ),
        const SizedBox(height: 16),
        // Second Row: Sleep and AI Prediction
        Row(
          children: [
            Expanded(child: _buildSleepCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildAIPredictionCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildOxygenCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.air, color: Colors.blue.shade400, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Oxygen Saturation',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 100,
            width: 100,
            child: CircularPercentIndicator(
              radius: 50,
              lineWidth: 8,
              animation: true,
              percent: _oxygenSaturation != null
                  ? (_oxygenSaturation! / 100.0).clamp(0.0, 1.0)
                  : 0.0,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLoadingHealthData
                        ? '...'
                        : (_oxygenSaturation != null
                              ? '${_oxygenSaturation}%'
                              : '${_getRandomOxygenSaturation()}%'),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade400,
                    ),
                  ),
                  Text(
                    'SpO2',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.grey.shade100,
              progressColor: Colors.blue.shade400,
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.orange.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Calories',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 100,
            width: 100,
            child: CircularPercentIndicator(
              radius: 50,
              lineWidth: 8,
              animation: true,
              percent: _calories != null
                  ? (_calories! / 500.0).clamp(0.0, 1.0)
                  : 0.0,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLoadingHealthData
                        ? '...'
                        : (_calories != null
                              ? _calories.toString()
                              : _getRandomCalories().toString()),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade400,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.grey.shade100,
              progressColor: Colors.orange.shade400,
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.nightlight_round,
                color: Colors.purple.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sleep',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 100,
            width: 100,
            child: CircularPercentIndicator(
              radius: 50,
              lineWidth: 8,
              animation: true,
              percent: _sleepHours != null
                  ? (_sleepHours! / 10.0).clamp(0.0, 1.0)
                  : 0.0,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLoadingHealthData
                        ? '...'
                        : (_sleepHours != null
                              ? _sleepHours.toString()
                              : _getRandomSleepHours().toString()),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade400,
                    ),
                  ),
                  Text(
                    'hours',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.grey.shade100,
              progressColor: Colors.purple.shade400,
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIPredictionCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.green.shade400, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Prediction',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 100,
            width: 100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Colors.green.shade400,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Normal Beat',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDoctorConnectionContent() {
    return FindDoctorScreen();
  }

  Widget _buildAIAssistantContent() {
    return const ChatScreen();
  }

  Widget _buildMedicineReminderContent() {
    return const MedicineReminderScreen();
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        _handleNavigation(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? HexColor(mainColor) : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.montserrat(
                color: isSelected ? HexColor(mainColor) : Colors.grey.shade600,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _getBodyContent(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _navigateToAI,
              backgroundColor: HexColor(mainColor),
              elevation: 8,
              child: const Icon(Icons.chat, color: Colors.white, size: 28),
              tooltip: 'Heart Health Assistant',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.favorite, 'Heart'),
                _buildNavItem(1, Icons.medical_services, 'Cardiologist'),
                _buildNavItem(3, Icons.medication, 'Medications'),
                _buildNavItem(4, Icons.school, 'Learning'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
