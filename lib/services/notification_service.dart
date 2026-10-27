import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/motorcycle.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _enabled = true;

  static const String _channelId = 'motorqu_reminder';
  static const String _channelName = 'Pengingat Ganti Oli';
  static const String _channelDesc = 'Notifikasi cek oli tiap 30 hari';

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // fallback ke lokasi default bila zona waktu tidak dikenal
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(initSettings);

    // Minta izin notifikasi utk Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }
  void setEnabled(bool v) => _enabled = v;

  Future<bool> requestPermission() async {
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> showTestNotification() async {
    try {
      if (!_initialized) await init();
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        999,
        'Pengingat Ganti Oli MotorQu',
        'Notifikasi pengingat berfungsi dengan baik!',
        details,
      );
    } catch (_) {}
  }

  DateTime? _lastSyncTime;

  /// Sinkronisasi jadwal pengingat untuk SEMUA motor (motor pribadi maupun motor grup)
  Future<void> syncReminders(List<Motorcycle> motorcycles) async {
    if (!_enabled) return;
    final now = DateTime.now();
    if (_lastSyncTime != null && now.difference(_lastSyncTime!).inMinutes < 15) {
      return; // Cukup sinkronkan berkala agar tidak boros proses
    }
    _lastSyncTime = now;

    try {
      if (!_initialized) await init();

      for (final moto in motorcycles) {
        final target = moto.nextDueKm;
        final serviceDate = moto.lastServiceAt?.toDate();
        final tz.TZDateTime scheduledDate;

        if (serviceDate != null) {
          final dueDate = serviceDate.add(const Duration(days: 30));
          if (dueDate.isAfter(DateTime.now())) {
            scheduledDate = tz.TZDateTime.from(dueDate, tz.local);
          } else {
            // Sudah lewat 30 hari sejak servis terakhir, ingatkan dalam 1 jam
            scheduledDate =
                tz.TZDateTime.now(tz.local).add(const Duration(hours: 1));
          }
        } else {
          scheduledDate =
              tz.TZDateTime.now(tz.local).add(const Duration(days: 30));
        }

        const androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );
        const details = NotificationDetails(android: androidDetails);

        await _plugin.zonedSchedule(
          moto.id.hashCode,
          'Cek oli ${moto.name}',
          'Jika KM motor ${moto.name} sudah lebih dari ${target}KM, jangan lupa ganti oli yaa',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {}
  }

  Future<void> scheduleOilReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_enabled) return;
    try {
      if (!_initialized) await init();

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const details = NotificationDetails(android: androidDetails);

      final when = tz.TZDateTime.now(tz.local).add(const Duration(days: 30));

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Notifikasi lokal tidak boleh menggagalkan proses penyimpanan data
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
