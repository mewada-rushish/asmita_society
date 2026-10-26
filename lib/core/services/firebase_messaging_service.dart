import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/features/auth/data/repositories/auth_repository.dart';
import 'package:asmita_society/core/services/incoming_visitor_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('[NotificationBackgroundTap] action: ${notificationResponse.actionId}, payload: ${notificationResponse.payload}');
  final payloadStr = notificationResponse.payload;
  if (payloadStr != null && payloadStr.isNotEmpty) {
    try {
      final data = jsonDecode(payloadStr) as Map<String, dynamic>;
      if (notificationResponse.actionId == 'approve_action') {
        IncomingVisitorService.handleBackgroundDecision(data, 'APPROVE');
      } else if (notificationResponse.actionId == 'reject_action') {
        IncomingVisitorService.handleBackgroundDecision(data, 'REJECT');
      }
    } catch (e) {
      debugPrint('[NotificationBackgroundTap] Error: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");

  final eventType = message.data['event']?.toString() ??
      message.data['eventType']?.toString() ??
      message.data['event_type']?.toString() ??
      message.data['notification_type']?.toString() ??
      '';

  final isApproval = eventType == 'VISITOR_REQUEST' ||
      eventType == 'VISITOR_ARRIVAL' ||
      eventType == 'VISITOR_SUBMITTED' ||
      eventType == 'VISITOR_AWAITING_HOST' ||
      eventType == 'VISITOR_ASSIGNED' ||
      eventType == 'visitor_approval' ||
      eventType == 'approval' ||
      message.data['notification_type'] == 'visitor_approval' ||
      message.data['notification_type'] == 'approval' ||
      message.data['requires_approval'] == 'true';

  if (isApproval) {
    try {
      final localNotifications = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await localNotifications.initialize(
        settings: const InitializationSettings(android: initializationSettingsAndroid),
        onDidReceiveNotificationResponse: notificationTapBackground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      final title = message.notification?.title ??
          message.data['title'] ??
          'Visitor at Gate: ${message.data['visitor_name'] ?? 'Visitor'}';
      final body = message.notification?.body ??
          message.data['body'] ??
          '${message.data['visitor_name'] ?? 'Visitor'} has arrived. Approval required.';

      const androidDetails = AndroidNotificationDetails(
        'approval_channel',
        'Visitor Approvals',
        channelDescription: 'Used for high-priority visitor entry approvals with sound.',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        sound: RawResourceAndroidNotificationSound('asmita_alert_1'),
        playSound: true,
        visibility: NotificationVisibility.public,
        actions: [
          AndroidNotificationAction(
            'approve_action',
            'Approve',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'reject_action',
            'Reject',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      await localNotifications.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('[BackgroundHandler] Error showing full-screen alert: $e');
    }
  }
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
    
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

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

    // Check cold-start from local notification (e.g. lock screen fullScreenIntent)
    try {
      final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        debugPrint('[FirebaseMessagingService] Launched via local notification payload: $payload');
        if (payload != null && payload.isNotEmpty) {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          IncomingVisitorService.onIncomingCallReceived(data);
        }
      }
    } catch (e) {
      debugPrint('[FirebaseMessagingService] Error checking notification launch details: $e');
    }

    // Check cold-start from FCM message
    try {
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FirebaseMessagingService] Launched via FCM initial message: ${initialMessage.data}');
        if (_isApproval(initialMessage.data)) {
          IncomingVisitorService.onIncomingCallReceived(initialMessage.data);
        }
      }
    } catch (e) {
      debugPrint('[FirebaseMessagingService] Error checking initial FCM message: $e');
    }
    
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

  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint('[NotificationResponse] action: ${response.actionId}, payload: ${response.payload}');
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        if (response.actionId == 'approve_action') {
          IncomingVisitorService.handleBackgroundDecision(data, 'APPROVE');
        } else if (response.actionId == 'reject_action') {
          IncomingVisitorService.handleBackgroundDecision(data, 'REJECT');
        } else {
          IncomingVisitorService.onIncomingCallReceived(data);
        }
      } catch (e) {
        debugPrint('[NotificationResponse] Error parsing payload: $e');
      }
    }
  }

  bool _isApproval(Map<String, dynamic> data) {
    final eventType = data['event']?.toString() ??
        data['eventType']?.toString() ??
        data['event_type']?.toString() ??
        data['notification_type']?.toString() ??
        '';

    return eventType == 'VISITOR_REQUEST' ||
        eventType == 'VISITOR_ARRIVAL' ||
        eventType == 'VISITOR_SUBMITTED' ||
        eventType == 'VISITOR_AWAITING_HOST' ||
        eventType == 'VISITOR_ASSIGNED' ||
        eventType == 'visitor_approval' ||
        eventType == 'approval' ||
        data['notification_type'] == 'visitor_approval' ||
        data['notification_type'] == 'approval' ||
        data['requires_approval'] == 'true';
  }

  Future<void> syncToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint("[FirebaseMessagingService] syncToken fetched fresh token: $token");
        await _secureStorage.write(key: 'fcm_token', value: token);
        await _syncTokenToBackend(token);
      }
    } catch (e) {
      debugPrint("Failed to syncToken: $e");
    }
  }

  Future<void> _syncTokenToBackend(String token) async {
    try {
      final sessionToken = await _secureStorage.getToken();
      if (sessionToken != null && sessionToken.isNotEmpty) {
        await _authRepository.updateFcmToken(token);
        debugPrint("[FirebaseMessagingService] Successfully synced FCM token to backend.");
      } else {
        debugPrint("[FirebaseMessagingService] Session token not available yet; cached FCM token in SecureStorage.");
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

    final eventType = message.data['event']?.toString() ??
        message.data['eventType']?.toString() ??
        message.data['event_type']?.toString() ??
        message.data['notification_type']?.toString() ??
        '';

    final userApprovalSound = await _secureStorage.getApprovalSound();
    final userNotifSound = await _secureStorage.getNotificationSound();

    final isApproval = _isApproval(message.data);
    final isEscalation = eventType == 'ESCALATION' || eventType == 'VISITOR_ESCALATED';

    // Show full-screen Doorbell Overlay / Modal immediately
    if (isApproval) {
      final soundAsset = userApprovalSound == 'asmita_alert_2'
          ? 'assets/audio/notifications/approvals/AsmitA Alert 2.wav'
          : 'assets/audio/notifications/approvals/AsmitA Alert 1.wav';

      IncomingVisitorService.onIncomingCallReceived(
        message.data,
        soundAsset: soundAsset,
      );
    }

    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        (isApproval
            ? 'Visitor at Gate: ${message.data['visitor_name'] ?? 'Visitor'}'
            : 'AsmitA Notification');
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        (isApproval
            ? '${message.data['visitor_name'] ?? 'Visitor'} has arrived. Tap to approve or reject.'
            : '');

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

    final bool isDoorbellAlert = isApproval || isEscalation;

    _localNotifications.show(
      id: message.messageId.hashCode,
      title: title,
      body: body,
      payload: jsonEncode(message.data),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: isDoorbellAlert ? Priority.max : Priority.high,
          category: isDoorbellAlert ? AndroidNotificationCategory.call : AndroidNotificationCategory.event,
          fullScreenIntent: isDoorbellAlert,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
          sound: RawResourceAndroidNotificationSound(soundName),
          playSound: true,
          actions: isDoorbellAlert
              ? const [
                  AndroidNotificationAction(
                    'approve_action',
                    'Approve',
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                  AndroidNotificationAction(
                    'reject_action',
                    'Reject',
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                ]
              : null,
        ),
        iOS: DarwinNotificationDetails(
          sound: '$soundName.wav',
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          interruptionLevel: isDoorbellAlert ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
        ),
      ),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published! data: ${message.data}');
    if (_isApproval(message.data)) {
      IncomingVisitorService.onIncomingCallReceived(message.data);
    }
  }
}
