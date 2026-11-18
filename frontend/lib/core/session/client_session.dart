import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final clientSessionProvider = ChangeNotifierProvider<ClientSession>((ref) {
  final authState = ref.watch(authProvider);
  final session = ClientSession(authState);
  session.init();
  return session;
});

class ClientSession extends ChangeNotifier {
  static const String _keyGuestId = 'playned_client_guest_id';
  static const String _keyGuestName = 'playned_client_guest_name';

  final AuthState _authState;
  String _guestId = '';
  String _guestName = '';
  bool _isInitialized = false;

  ClientSession(this._authState);

  bool get isInitialized => _isInitialized;

  String get playerId {
    if (_authState.isLoggedIn && _authState.userId != null && _authState.userId!.isNotEmpty) {
      return _authState.userId!;
    }
    if (_guestId.isEmpty) {
      _guestId = _generateGuestId();
    }
    return _guestId;
  }

  String get playerName {
    if (_authState.isLoggedIn && _authState.username != null && _authState.username!.isNotEmpty) {
      return _authState.username!;
    }
    if (_guestName.isEmpty) {
      _guestName = 'Player_${_guestId.isNotEmpty ? _guestId.substring(max(0, _guestId.length - 4)) : 'Guest'}';
    }
    return _guestName;
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _guestId = prefs.getString(_keyGuestId) ?? '';
      if (_guestId.isEmpty) {
        _guestId = _generateGuestId();
        await prefs.setString(_keyGuestId, _guestId);
      }
      _guestName = prefs.getString(_keyGuestName) ?? '';
      if (_guestName.isEmpty) {
        final suffix = _guestId.length >= 4 ? _guestId.substring(_guestId.length - 4) : 'G';
        _guestName = 'Player_$suffix';
        await prefs.setString(_keyGuestName, _guestName);
      }
      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      if (_guestId.isEmpty) _guestId = _generateGuestId();
      if (_guestName.isEmpty) _guestName = 'Player_Guest';
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setGuestName(String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty) return;
    _guestName = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyGuestName, clean);
    } catch (_) {}
    notifyListeners();
  }

  static String _generateGuestId() {
    final rand = Random();
    const chars = 'abcdef0123456789';
    final token = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'g_$token';
  }
}
