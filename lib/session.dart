import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'core/api.dart';
import 'core/config.dart';
import 'models.dart';

/// Signed-in driver, their assignments (live) and consent-based location sharing.
class DriverSession extends ChangeNotifier {
  DriverSession(this.api, this.tokens) {
    api.onSessionExpired = _signedOut;
  }

  final Api api;
  final TokenStore tokens;
  bool ready = false;
  String? name;
  bool mustChangePassword = false;
  bool get signedIn => name != null;

  List<Assignment>? assignments;
  Object? error;
  bool live = false;
  io.Socket? _socket;
  Timer? _poll;

  /// The driver's explicit choice (stored on the device). Location is only sent for an order out for delivery.
  bool shareLocation = false;
  StreamSubscription<Position>? _gps;
  String? _sharingOrderId;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  String? locationProblem;

  Future<void> init() async {
    await tokens.load();
    shareLocation = (await SharedPreferences.getInstance()).getBool('lt_share_location') ?? false;
    if (tokens.hasSession) await _loadMe();
    ready = true;
    notifyListeners();
  }

  Future<void> _loadMe() async {
    try {
      final r = await api.get<Map<String, dynamic>>('/api/v1/auth/me');
      final u = (r['user'] as Map).cast<String, dynamic>();
      if (u['role'] != 'driver') {
        await logout();
        return;
      }
      name = (u['name'] as String?) ?? '${u['email']}';
      mustChangePassword = u['mustChangePassword'] == true;
      if (!mustChangePassword) _start();
    } catch (_) {
      name = null;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final r = await api.post<Map<String, dynamic>>('/api/v1/auth/login', body: {'email': email, 'password': password, 'client': 'mobile'});
    if ((r['user'] as Map)['role'] != 'driver') {
      await api.post('/api/v1/auth/logout', body: {'refreshToken': r['refreshToken']}).catchError((_) => null);
      throw ApiException(403, 'NOT_DRIVER', 'Not a driver account');
    }
    await tokens.save(r['accessToken'] as String, r['refreshToken'] as String);
    await _loadMe();
  }

  Future<void> changePassword(String current, String next) async {
    final r = await api.post<Map<String, dynamic>>('/api/v1/auth/change-password', body: {'currentPassword': current, 'newPassword': next, 'client': 'mobile'});
    await tokens.save(r['accessToken'] as String, r['refreshToken'] as String);
    await _loadMe();
  }

  Future<void> logout() async {
    final rt = tokens.refresh;
    if (rt != null) {
      try {
        await api.post('/api/v1/auth/logout', body: {'refreshToken': rt});
      } catch (_) {}
    }
    await tokens.clear();
    _signedOut();
  }

  void _signedOut() {
    _stopGps();
    _poll?.cancel();
    _socket?.dispose();
    _socket = null;
    live = false;
    name = null;
    assignments = null;
    notifyListeners();
  }

  void _start() {
    refresh();
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    _socket?.dispose();
    final s = io.io(
      AppConfig.apiUrl,
      io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().enableForceNew().enableReconnection().setAuth({'token': tokens.access}).build(),
    );
    // Drivers are put in their own room by the server on connect (no join needed).
    s.onConnect((_) {
      live = true;
      notifyListeners();
      refresh();
    });
    s.onDisconnect((_) {
      live = false;
      notifyListeners();
    });
    s.onReconnectAttempt((_) => s.auth = {'token': tokens.access});
    s.onConnectError((_) => api.get<dynamic>('/api/v1/auth/me').catchError((_) => null));
    s.on('order.created', (_) => refresh());
    s.on('order.updated', (_) => refresh());
    s.connect();
    _socket = s;
  }

  Future<void> refresh() async {
    try {
      final r = await api.get<Map<String, dynamic>>('/api/v1/driver/assignments');
      final next = (r['items'] as List).map((x) => Assignment.fromJson((x as Map).cast<String, dynamic>())).toList();
      // Alert for deliveries newly assigned to me (not on the first load).
      final known = assignments?.map((a) => a.id).toSet();
      if (known != null && next.any((a) => a.canRespond && !known.contains(a.id))) {
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
      }
      assignments = next;
      error = null;
    } catch (e) {
      error = e;
    }
    _syncGps();
    notifyListeners();
  }

  Future<void> act(Assignment a, String action) async {
    await api.post('/api/v1/driver/assignments/${a.id}/$action', body: {});
    await refresh();
  }

  Future<List<Assignment>> history() async {
    final r = await api.get<Map<String, dynamic>>('/api/v1/driver/history');
    return (r['items'] as List).map((x) => Assignment.fromJson((x as Map).cast<String, dynamic>())).toList();
  }

  // ---------------------------------------------------------------- location (consent, foreground only)
  Future<void> setShareLocation(bool on) async {
    if (on) {
      final ok = await _ensurePermission();
      if (!ok) {
        shareLocation = false;
        notifyListeners();
        return;
      }
    }
    shareLocation = on;
    (await SharedPreferences.getInstance()).setBool('lt_share_location', on);
    _syncGps();
    notifyListeners();
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      locationProblem = 'Activa la ubicación del teléfono.';
      return false;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
      locationProblem = 'Sin permiso de ubicación. Puedes darlo en los ajustes del teléfono.';
      return false;
    }
    locationProblem = null;
    return true;
  }

  /// Streams GPS only while sharing is on AND one of my deliveries is on its way; stops otherwise.
  void _syncGps() {
    final active = assignments?.where((a) => a.onTheWay).firstOrNull;
    if (!shareLocation || active == null) return _stopGps();
    if (_sharingOrderId == active.id && _gps != null) return;
    _stopGps();
    _sharingOrderId = active.id;
    _gps = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 25)).listen((pos) async {
      if (DateTime.now().difference(_lastSent).inSeconds < 15) return; // at most every 15 s
      _lastSent = DateTime.now();
      try {
        await api.post('/api/v1/driver/location', body: {'orderId': active.id, 'lat': pos.latitude, 'lng': pos.longitude, 'accuracy': pos.accuracy, 'consent': true});
      } catch (_) {/* delivery may have just been completed */}
    }, onError: (_) => _stopGps());
  }

  void _stopGps() {
    _gps?.cancel();
    _gps = null;
    _sharingOrderId = null;
  }

  @override
  void dispose() {
    _signedOut();
    super.dispose();
  }
}
