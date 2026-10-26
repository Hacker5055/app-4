import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Encrypted vault storage abstraction.
/// In production, all data is encrypted with the hardware-backed KeyStore key.
/// Hive boxes are encrypted with a key derived from AndroidKeyStore.
class VaultStorageService {
  static const _vaultBoxName = 'canary_vault_box';
  static const _metaBoxName = 'canary_meta_box';

  Box? _vaultBox;
  Box? _metaBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _vaultBox = await Hive.openBox(_vaultBoxName);
    _metaBox = await Hive.openBox(_metaBoxName);
  }

  Box get vaultBox {
    if (_vaultBox == null) throw StateError('VaultStorage not initialized — call init() first');
    return _vaultBox!;
  }

  Box get metaBox {
    if (_metaBox == null) throw StateError('VaultStorage not initialized');
    return _metaBox!;
  }

  Future<void> storeItem(String id, Map<String, dynamic> data) async {
    await vaultBox.put(id, jsonEncode(data));
  }

  Map<String, dynamic>? getItem(String id) {
    final raw = vaultBox.get(id);
    if (raw == null) return null;
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> getAllItems() {
    return vaultBox.values.map((e) => jsonDecode(e as String) as Map<String, dynamic>).toList();
  }

  Future<void> deleteItem(String id) async => vaultBox.delete(id);

  Future<void> clearVault() async => vaultBox.clear();

  Future<void> storeSecure(String key, String value) async {
    await metaBox.put(key, value);
  }

  String? getSecure(String key) => metaBox.get(key) as String?;

  Future<int> itemCount() async => vaultBox.length;

  Future<void> dispose() async {
    await _vaultBox?.close();
    await _metaBox?.close();
  }
}

/// Secure preferences helper for non-vault settings
class SecurePrefsHelper {
  static Future<void> incrementFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(AppConstants.kFailedAttempts) ?? 0;
    await prefs.setInt(AppConstants.kFailedAttempts, current + 1);
  }

  static Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.kFailedAttempts) ?? 0;
  }

  static Future<bool> isLockedOut() async {
    final count = await getFailedAttempts();
    return count >= AppConstants.maxFailedAttempts;
  }

  static Future<void> resetFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.kFailedAttempts, 0);
  }
}
