import 'dart:io' show Platform, File, FileSystemEntity;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'job_search_channel',
        'Job Search Notifications',
        description: 'Notifications for saved job searches',
        importance: Importance.defaultImportance,
      );

  static const AndroidNotificationChannel _androidExportChannel =
      AndroidNotificationChannel(
        'file_exports_channel',
        'File Export Notifications',
        description: 'Notifications for exported files and packages',
        importance: Importance.high,
      );

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Android: create notification channels
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(_androidChannel);
      await androidImpl.createNotificationChannel(_androidExportChannel);
      // Android 13+ notifications permission
      await androidImpl.requestNotificationsPermission();
    }

    // iOS: request permission
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      await iosImpl.requestPermissions(alert: true, badge: true, sound: false);
    }

    _initialized = true;
  }

  static void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;
    
    if (payload == null) return;
    
    // Handle different action buttons
    if (actionId == 'share') {
      // Share button was tapped
      _shareLocation(payload);
    } else {
      // Main notification tap (or other actions)
      _openFileOrFolder(payload);
    }
  }

  static Future<void> show({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await init();
    }

    if (kIsWeb) return; // Not supported on web

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  /// Show notification for file export with tap to open
  static Future<void> showFileExport({
    required String title,
    required String filePath,
    bool isPackage = false,
  }) async {
    if (!_initialized) {
      await init();
    }

    if (kIsWeb) return;
    
    // Ensure the file exists before showing notification
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('File does not exist: $filePath');
      return;
    }

    final String channelName = isPackage ? 'file_exports_channel' : 'file_exports_channel';
    
    // Get just the filename for cleaner display
    final fileName = filePath.split(Platform.pathSeparator).last;
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelName,
      isPackage ? 'Package Exports' : 'File Exports',
      channelDescription: isPackage 
          ? 'Notifications for application packages' 
          : 'Notifications for exported files',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      styleInformation: BigTextStyleInformation(
        isPackage 
            ? 'Complete application package saved\nTap to share location'
            : 'File saved: $fileName\nTap to share location',
      ),
      actions: [
        AndroidNotificationAction(
          'share',
          'Share',
          showsUserInterface: false,
        ),
      ],
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      isPackage 
          ? 'Complete application package ready' 
          : 'File saved to Downloads folder',
      platformDetails,
      payload: filePath,
    );
  }

  /// Handle opening files or folders from notification tap
  static Future<void> _openFileOrFolder(String path) async {
    try {
      final file = File(path);
      final exists = await file.exists();

      if (!exists) {
        // Try opening parent folder
        final parentPath = path.substring(0, path.lastIndexOf(Platform.pathSeparator));
        await _shareLocation(parentPath);
        return;
      }

      // Check if it's a directory
      if (await FileSystemEntity.isDirectory(path)) {
        await _shareLocation(path);
      } else {
        // Share the file location
        await _shareLocation(path);
      }
    } catch (e) {
      debugPrint('Error opening file/folder: $e');
      // Fallback: try to share parent folder
      try {
        final parentPath = path.substring(0, path.lastIndexOf(Platform.pathSeparator));
        await _shareLocation(parentPath);
      } catch (e2) {
        debugPrint('Fallback also failed: $e2');
      }
    }
  }

  /// Share the file/folder location using share_plus
  static Future<void> _shareLocation(String path) async {
    try {
      // Try to share the file directly if it exists
      final file = File(path);
      if (await file.exists() && !await FileSystemEntity.isDirectory(path)) {
        // Share the file
        await Share.shareXFiles([XFile(path)], text: 'Exported file');
      } else {
        // Share the path as text
        final message = 'File location:\n$path\n\nYou can use your file manager to navigate to this location.';
        await Share.share(message);
      }
    } catch (e) {
      debugPrint('Error sharing location: $e');
      // If sharing fails, show the path in a message
      final message = 'File saved at:\n$path\n\nPlease use your file manager to access it.';
      try {
        await Share.share(message);
      } catch (e2) {
        // If share also fails, just show in console
        debugPrint('File location: $path');
      }
    }
  }

  /// Show a simple notification with a message
  static Future<void> showMessage({
    required String title,
    required String message,
  }) async {
    if (!_initialized) {
      await init();
    }

    if (kIsWeb) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'General messages',
      importance: Importance.low,
      priority: Priority.low,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      message,
      platformDetails,
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
