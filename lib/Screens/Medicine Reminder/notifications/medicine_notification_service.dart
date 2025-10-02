import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import '../database/medicine_database.dart';

class MedicineNotificationService {
  static final MedicineNotificationService _instance = MedicineNotificationService._internal();
  factory MedicineNotificationService() => _instance;
  MedicineNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    _isInitialized = true;
  }

  Future<void> _requestAndroidPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to medicine screen
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleMedicineReminder(Medicine medicine) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('🔔 Scheduling notification for medicine: ${medicine.name}');
      print('🔔 Medicine time: ${medicine.time}');
      
      // Check if notifications are enabled
      final notificationsEnabled = await areNotificationsEnabled();
      if (!notificationsEnabled) {
        print(' Notifications are not enabled on this device');
        return;
      }

      // Parse time from medicine.time (format: "HH:MM AM/PM" or "HH:MM")
      final timeParts = medicine.time.split(' ');
      final timeString = timeParts[0]; // "HH:MM"
      final period = timeParts.length > 1 ? timeParts[1] : ''; // "AM", "PM", or empty
      
      print('🔔 Parsed time: $timeString $period');
      
      final timeComponents = timeString.split(':');
      int hour = int.parse(timeComponents[0]);
      final minute = int.parse(timeComponents[1]);

      // Convert to 24-hour format only if period is specified
      if (period.isNotEmpty) {
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      }
      // If no period is specified, assume it's already in 24-hour format

      print('🔔 Converted to 24-hour format: $hour:$minute');

      // Create notification ID based on medicine ID
      final notificationId = medicine.id ?? DateTime.now().millisecondsSinceEpoch;
      print('🔔 Notification ID: $notificationId');

      // Get the next notification time
      final scheduledTime = _getNextNotificationTime(hour, minute);
      print('🔔 Scheduled time: $scheduledTime');

      // Schedule daily notification
      await _notifications.zonedSchedule(
        notificationId,
        'Medicine Reminder',
        'Time to take ${medicine.name} (${medicine.dose} ${medicine.shape})',
        scheduledTime,
        _getNotificationDetails(medicine),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'medicine_${medicine.id}',
      );

      print(' Successfully scheduled notification for ${medicine.name} at ${medicine.time}');
      
      // Verify the notification was scheduled
      final pendingNotifications = await getPendingNotifications();
      print('🔔 Total pending notifications: ${pendingNotifications.length}');
      
    } catch (e) {
      print(' Error scheduling notification: $e');
      print(' Stack trace: ${StackTrace.current}');
    }
  }

  tz.TZDateTime _getNextNotificationTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  NotificationDetails _getNotificationDetails(Medicine medicine) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Future<void> cancelMedicineReminder(int medicineId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _notifications.cancel(medicineId);
      print('Cancelled notification for medicine ID: $medicineId');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllMedicineReminders() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _notifications.cancelAll();
      print('Cancelled all medicine notifications');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  Future<void> rescheduleAllMedicines() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Cancel all existing notifications
      await cancelAllMedicineReminders();

      // Get all medicines from database
      final db = MedicineDatabase();
      final medicines = await db.getAllMedicines();

      // Schedule notifications for all medicines
      for (final medicine in medicines) {
        await scheduleMedicineReminder(medicine);
      }

      print('Rescheduled notifications for ${medicines.length} medicines');
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) {
      await initialize();
    }

    return await _notifications.pendingNotificationRequests();
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      return await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  // Test function to send an immediate notification
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('🧪 Sending test notification...');
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription: 'Notifications for medicine reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        999, // Test notification ID
        'Test Medicine Reminder',
        'This is a test notification to verify the system is working',
        notificationDetails,
        payload: 'test_notification',
      );

      print(' Test notification sent successfully');
    } catch (e) {
      print(' Error sending test notification: $e');
    }

  }

  // Function to check and log all pending notifications
  Future<void> debugPendingNotifications() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final pendingNotifications = await getPendingNotifications();
      print(' Debug: Found ${pendingNotifications.length} pending notifications');
      
      for (final notification in pendingNotifications) {
        print(' Notification ID: ${notification.id}');
        print(' Title: ${notification.title}');
        print(' Body: ${notification.body}');
        print(' Payload: ${notification.payload}');
        print('---');
      }
    } catch (e) {
      print(' Error getting pending notifications: $e');
    }
  }
}
