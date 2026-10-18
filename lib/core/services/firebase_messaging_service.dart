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
    final visitorChannels = [
      const AndroidNotificationChannel(
        'asmita_visitor_requests',
        'Visitor Entry Requests',
        description: 'Alerts when a new visitor requests entry.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_request'),
      ),
      const AndroidNotificationChannel(
        'asmita_visitor_approvals',
        'Visitor Entry Approvals',
        description: 'Alerts when visitor entry is approved.',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_approval'),
      ),
      const AndroidNotificationChannel(
        'asmita_visitor_rejections',
        'Visitor Entry Rejections',
        description: 'Alerts when visitor entry is rejected or pass revoked.',
        importance: Importance.defaultImportance,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_rejection'),
      ),
      const AndroidNotificationChannel(
        'asmita_visitor_escalations',
        'Visitor Escalation Alerts',
        description: 'High priority alert when unacknowledged visitor escalates to Head or Receptionist.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_escalation'),
      ),
      const AndroidNotificationChannel(
        'asmita_guard_alerts',
        'Security Guard Gate Alerts',
        description: 'Targeted vehicle approvals and unattended gate failover alerts.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_guard'),
      ),
      const AndroidNotificationChannel(
        'approval_channel',
        'Visitor Approvals',
        description: 'Used for visitor entry approvals.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_alert_1'),
      ),
      const AndroidNotificationChannel(
        'campaign_channel',
        'Campaigns & Announcements',
        description: 'Used for society announcements and campaigns.',
        importance: Importance.defaultImportance,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_notification_1'),
      ),
    ];

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    for (final channel in visitorChannels) {
      await androidPlugin?.createNotificationChannel(channel);
    }

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

    // Handle Silent Push Dismissal (dismiss handled approval cards across devices)
    if (message.data['action'] == 'DISMISS_MODAL' || message.data['event'] == 'VISITOR_DECIDED') {
      debugPrint('[FirebaseMessagingService] Received silent dismissal for requestId: ${message.data['requestId']}');
      return;
    }

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
      
      final notification = message.notification;
      final android = message.notification?.android;
      
      if (notification != null && android != null) {
        final eventType = message.data['event']?.toString() ?? message.data['eventType']?.toString();
        String channelId = 'approval_channel';
        String channelName = 'Visitor Approvals';
        String soundName = 'asmita_alert_1';

        if (eventType == 'VISITOR_REQUEST') {
          channelId = 'asmita_visitor_requests';
          channelName = 'Visitor Entry Requests';
          soundName = 'asmita_request';
        } else if (eventType == 'VISITOR_APPROVED') {
          channelId = 'asmita_visitor_approvals';
          channelName = 'Visitor Entry Approvals';
          soundName = 'asmita_approval';
        } else if (eventType == 'VISITOR_REJECTED' || eventType == 'PASS_REVOKED') {
          channelId = 'asmita_visitor_rejections';
          channelName = 'Visitor Entry Rejections';
          soundName = 'asmita_rejection';
        } else if (eventType == 'ESCALATION') {
          channelId = 'asmita_visitor_escalations';
          channelName = 'Visitor Escalation Alerts';
          soundName = 'asmita_escalation';
        } else if (eventType == 'GUARD_DUTY_FAILOVER' || eventType == 'VEHICLE_APPROVED') {
          channelId = 'asmita_guard_alerts';
          channelName = 'Security Guard Gate Alerts';
          soundName = 'asmita_guard';
        }
        
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              sound: RawResourceAndroidNotificationSound(soundName),
            ),
            iOS: DarwinNotificationDetails(
              sound: '$soundName.wav',
            ),
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
