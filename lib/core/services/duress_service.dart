import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../platform/method_channel_service.dart';

/// Core duress engine — handles dual-PIN verification, key purge orchestration,
/// and action dispatch. All cryptographic operations delegate to native KeyStore.
class DuressService {
  final MethodChannelService _native;

  DuressService(this._native);

  // ── PIN Hashing (SHA-256 with app-specific pepper) ──
  // Native layer does the real key derivation; this is for quick PIN comparison.
  static String hashPin(String pin) {
    const pepper = 'CanaryDuressLock_v1_pepper_Sphinx_2024';
    final bytes = utf8.encode('$pepper::$pin');
    return sha256.convert(bytes).toString();
  }

  Future<void> setMasterPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kMasterPinHash, hashPin(pin));
    await prefs.setBool(AppConstants.kVaultInitialized, true);
    // Generate hardware-backed key for vault encryption
    await _native.generateMasterKey();
  }

  Future<void> setDuressPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kDuressPinHash, hashPin(pin));
  }

  Future<void> setDuressAction(int action) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.kDuressAction, action);
  }

  Future<int> getDuressAction() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.kDuressAction) ?? AppConstants.duressActionDecoyAndPurge;
  }

  Future<bool> isMockTestingMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.kMockTestingMode) ?? false;
  }

  Future<void> setMockTestingMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.kMockTestingMode, enabled);
  }

  Future<int> failedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.kFailedAttempts) ?? 0;
  }

  Future<void> resetFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.kFailedAttempts, 0);
  }

  Future<bool> hasPinSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(AppConstants.kMasterPinHash);
  }

  /// Verifies PIN and returns authentication result.
  /// This is the critical dual-PIN dispatch — must be constant-time.
  Future<AuthResult> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final masterHash = prefs.getString(AppConstants.kMasterPinHash);
    final duressHash = prefs.getString(AppConstants.kDuressPinHash);
    final inputHash = hashPin(pin);

    if (masterHash == null) {
      return AuthResult.invalid;
    }

    // Check duress PIN first (if set) — duress takes precedence
    if (duressHash != null && inputHash == duressHash) {
      return AuthResult.duress;
    }

    if (inputHash == masterHash) {
      // Record successful unlock
      await prefs.setString(AppConstants.kLastUnlockTime, DateTime.now().toIso8601String());
      await prefs.setInt(AppConstants.kFailedAttempts, 0);
      return AuthResult.master;
    }

    // Failed attempt tracking
    final fails = (prefs.getInt(AppConstants.kFailedAttempts) ?? 0) + 1;
    await prefs.setInt(AppConstants.kFailedAttempts, fails);
    return AuthResult.invalid;
  }

  /// Executes the full duress sequence: purge keys, zero memory, trigger wipe if configured.
  Future<DuressExecutionLog> executeDuressSequence() async {
    final log = DuressExecutionLog();
    final isMock = await isMockTestingMode();
    final action = await getDuressAction();

    log.add('DURESS TRIGGERED — Action: ${AppConstants.duressActionLabel(action)}');
    log.add('Mock Testing Mode: $isMock');

    if (isMock) {
      // Mock mode: log actions without actually wiping
      log.add('[MOCK] Simulating KeyStore purge for alias: ${AppConstants.masterKeyAlias}');
      await Future.delayed(const Duration(milliseconds: 400));
      log.add('[MOCK] KeyStore entry deleted — AES-256 key purged');
      await Future.delayed(const Duration(milliseconds: 200));
      log.add('[MOCK] Memory zeroization — byte arrays wiped (Arrays.fill 0x00)');
      await Future.delayed(const Duration(milliseconds: 200));
      log.add('[MOCK] Secure storage cleared — vault metadata erased');
      if (action == AppConstants.duressActionHardWipe) {
        log.add('[MOCK] DeviceAdmin wipe would execute: devicePolicyManager.wipeData(0)');
        log.add('[MOCK]BLOCKED — Mock mode prevents actual wipe');
      }
      log.add('MOCK SEQUENCE COMPLETE — No data was actually deleted');
      _incrementDuressCounter();
      return log;
    }

    // ── REAL EXECUTION ──
    try {
      log.add('Executing hardware-backed key purge...');
      final purgeResult = await _native.purgeAllKeys();
      log.add(purgeResult ? 'KeyStore PURGED — alias deleted from StrongBox/TEE' : 'KeyStore purge returned false');

      log.add('Zeroizing memory buffers...');
      final zeroResult = await _native.zeroizeMemory();
      log.add(zeroResult ? 'Memory ZEROIZED — all byte arrays overwritten' : 'Memory zeroization incomplete');

      log.add('Clearing secure storage layer...');
      await _native.clearSecureStorage();
      log.add('Secure storage cleared');

      if (action == AppConstants.duressActionHardWipe) {
        log.add('HARD WIPE — invoking DevicePolicyManager.wipeData(0)');
        final wipeResult = await _native.triggerDeviceWipe();
        log.add(wipeResult ? 'WIPE COMMAND SENT — device will factory reset' : 'Wipe requires Device Admin activation');
      }

      _incrementDuressCounter();
      log.add('DURESS SEQUENCE COMPLETE');
    } catch (e) {
      log.add('ERROR during duress sequence: $e');
    }

    return log;
  }

  Future<void> _incrementDuressCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(AppConstants.kDuressTriggeredCount) ?? 0) + 1;
    await prefs.setInt(AppConstants.kDuressTriggeredCount, count);
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      await _native.purgeAllKeys();
    } catch (_) {}
  }
}

enum AuthResult { master, duress, invalid }

class DuressExecutionLog {
  final List<String> entries = [];
  final DateTime timestamp = DateTime.now();

  void add(String entry) {
    final time = DateTime.now().toIso8601String().split('T').last.split('.').first;
    entries.add('[$time] $entry');
  }

  String get formatted => entries.join('\n');

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'entries': entries,
      };
}
