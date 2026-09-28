import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

import 'package:asmita_society/features/auth/data/repositories/auth_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SecureStorageService _secureStorage;
  final AuthRepository _authRepository;

  FirebaseMessagingService(this._secureStorage, this._authRepository);

  Future<void> initialize() async {
    // Request permissions for iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(settings: initializationSettings);

    // Create Android notification channels
    const AndroidNotificationChannel approvalChannel = AndroidNotificationChannel(
      'approval_channel', // id
      'Visitor Approvals', // title
      description: 'Used for visitor entry approvals.', // description
      importance: Importance.max,
      playSound: true,
      // sound: RawResourceAndroidNotificationSound('approval_tone'), // Add later
    );

    const AndroidNotificationChannel campaignChannel = AndroidNotificationChannel(
      'campaign_channel', // id
      'Campaigns & Announcements', // title
      description: 'Used for society announcements and campaigns.', // description
      importance: Importance.defaultImportance,
      playSound: true,
      // sound: RawResourceAndroidNotificationSound('campaign_tone'), // Add later
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(approvalChannel);
        
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(campaignChannel);

    // Setup message handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Get and save FCM token
    String? token;
    try {
      token = await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint("Failed to get Firebase token: $e");
    }
    if (token != null) {
      debugPrint("FCM Token: $token");
      await _secureStorage.write(key: 'fcm_token', value: token);
      await _syncTokenToBackend(token);
    }
    
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM Token Refreshed: $newToken");
      await _secureStorage.write(key: 'fcm_token', value: newToken);
      await _syncTokenToBackend(newToken);
    });
  }

  Future<void> _syncTokenToBackend(String token) async {
    try {
      final sessionToken = await _secureStorage.getToken();
      if (sessionToken != null && sessionToken.isNotEmpty) {
        await _authRepository.updateFcmToken(token);
      }
    } catch (e) {
      debugPrint("Failed to sync FCM token to backend: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
      
      final notification = message.notification;
      final android = message.notification?.android;
      
      if (notification != null && android != null) {
        // Determine the channel based on data payload
        final isApproval = message.data['notification_type'] == 'approval';
        
        final channelId = isApproval ? 'approval_channel' : 'campaign_channel';
        final channelName = isApproval ? 'Visitor Approvals' : 'Campaigns & Announcements';
        final channelDesc = isApproval ? 'Used for visitor entry approvals.' : 'Used for society announcements and campaigns.';
        
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: channelDesc,
              importance: isApproval ? Importance.max : Importance.defaultImportance,
              priority: isApproval ? Priority.high : Priority.defaultPriority,
              icon: '@mipmap/ic_launcher',
              // sound: RawResourceAndroidNotificationSound(isApproval ? 'approval_tone' : 'campaign_tone'),
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');
    // Handle navigation or other logic when app is opened from notification
  }
}
