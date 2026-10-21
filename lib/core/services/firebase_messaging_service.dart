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

    // Ensure foreground notifications display alerts and play sounds on iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
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
        'escalation_channel',
        'Urgent Escalations',
        description: 'Urgent visitor escalation alerts.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_alert_urgent'),
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
        'Visitor Approvals (Default)',
        description: 'Used for visitor entry approvals with default sound.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_alert_1'),
      ),
      const AndroidNotificationChannel(
        'approval_channel_2',
        'Visitor Approvals (Alert 2)',
        description: 'Used for visitor entry approvals with alternative alert sound.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_alert_2'),
      ),
      const AndroidNotificationChannel(
        'campaign_channel',
        'Campaigns & Announcements (Default)',
        description: 'Used for society announcements with default sound.',
        importance: Importance.defaultImportance,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_notification_1'),
      ),
      const AndroidNotificationChannel(
        'campaign_channel_2',
        'Campaigns & Announcements (Sound 2)',
        description: 'Used for society announcements with alternative sound.',
        importance: Importance.defaultImportance,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('asmita_notification_2'),
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

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
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
      
      if (notification != null) {
        final eventType = message.data['event']?.toString() ??
            message.data['eventType']?.toString() ??
            message.data['event_type']?.toString() ??
            message.data['notification_type']?.toString() ??
            '';

        final userApprovalSound = await _secureStorage.getApprovalSound();
        final userNotifSound = await _secureStorage.getNotificationSound();

        final isApproval = eventType == 'VISITOR_REQUEST' ||
            eventType == 'VISITOR_ARRIVAL' ||
            eventType == 'VISITOR_SUBMITTED' ||
            eventType == 'VISITOR_AWAITING_HOST' ||
            eventType == 'VISITOR_ASSIGNED' ||
            eventType == 'visitor_approval';

        final isEscalation = eventType == 'ESCALATION' || eventType == 'VISITOR_ESCALATED';

        String channelId;
        String channelName;
        String soundName;

        if (isApproval) {
          channelId = userApprovalSound == 'asmita_alert_2' ? 'approval_channel_2' : 'approval_channel';
          channelName = 'Visitor Approvals';
          soundName = userApprovalSound;
        } else if (isEscalation) {
          channelId = 'escalation_channel';
          channelName = 'Urgent Escalations';
          soundName = userApprovalSound == 'asmita_alert_2' ? 'asmita_alert_2' : 'asmita_alert_urgent';
        } else if (eventType == 'VISITOR_APPROVED') {
          channelId = 'asmita_visitor_approvals';
          channelName = 'Visitor Entry Approvals';
          soundName = 'asmita_approval';
        } else if (eventType == 'VISITOR_REJECTED' ||
            eventType == 'PASS_REVOKED' ||
            eventType == 'VISITOR_CANCELLED') {
          channelId = 'asmita_visitor_rejections';
          channelName = 'Visitor Entry Rejections';
          soundName = 'asmita_rejection';
        } else if (eventType == 'GUARD_DUTY_FAILOVER' ||
            eventType == 'VEHICLE_APPROVED' ||
            eventType == 'guard_approval_alert') {
          channelId = 'asmita_guard_alerts';
          channelName = 'Security Guard Gate Alerts';
          soundName = 'asmita_guard';
        } else {
          // General / Campaign / Announcement notification
          channelId = userNotifSound == 'asmita_notification_2' ? 'campaign_channel_2' : 'campaign_channel';
          channelName = 'Campaigns & Announcements';
          soundName = userNotifSound;
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
