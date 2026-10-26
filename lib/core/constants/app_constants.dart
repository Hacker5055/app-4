/// Canary Duress Lock — Global Constants
class AppConstants {
  static const appName = 'Canary Duress Lock';
  static const appNameAr = 'نظام التمويه وقفل الطوارئ';
  static const packageName = 'com.canary.duresslock';

  // ── KeyStore Aliases ──
  static const masterKeyAlias = 'canary_master_vault_key_v1';
  static const biometricKeyAlias = 'canary_biometric_key_v1';
  static const pinHashAlias = 'canary_pin_hash_v1';

  // ── SharedPreferences Keys ──
  static const kMasterPinHash = 'master_pin_hash';
  static const kDuressPinHash = 'duress_pin_hash';
  static const kDuressAction = 'duress_action';
  static const kIsFirstLaunch = 'is_first_launch';
  static const kMockTestingMode = 'mock_testing_mode';
  static const kBiometricEnabled = 'biometric_enabled';
  static const kVaultInitialized = 'vault_initialized';
  static const kFailedAttempts = 'failed_attempts';
  static const kLastUnlockTime = 'last_unlock_time';
  static const kDuressTriggeredCount = 'duress_triggered_count';

  // ── PIN Specs ──
  static const pinLength = 6;
  static const maxFailedAttempts = 5;
  static const lockoutDurationMinutes = 5;

  // ── Duress Actions ──
  static const duressActionDecoyOnly = 1;
  static const duressActionDecoyAndPurge = 2;
  static const duressActionHardWipe = 3;

  static String duressActionLabel(int action) {
    switch (action) {
      case duressActionDecoyOnly:
        return 'Decoy Only — Show fake environment';
      case duressActionDecoyAndPurge:
        return 'Decoy + Purge — Delete keys & show decoy';
      case duressActionHardWipe:
        return 'Hard Wipe — Factory reset via Device Admin';
      default:
        return 'Unknown';
    }
  }

  // ── MethodChannel Names ──
  static const channelKeyStore = 'com.canary.duresslock/keystore';
  static const channelDeviceAdmin = 'com.canary.duresslock/device_admin';
  static const channelZeroizer = 'com.canary.duresslock/zeroizer';

  // ── Vault Categories ──
  static const vaultCategories = ['Photos', 'Documents', 'Credentials', 'Notes'];
}

/// Vault item model
class VaultItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final DateTime createdAt;
  final bool isEncrypted;
  final String? filePath;

  VaultItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.createdAt,
    this.isEncrypted = true,
    this.filePath,
  });
}

/// Mock vault data for demonstration
class MockVaultData {
  static final items = [
    VaultItem(
      id: '1',
      title: 'Passport Scan.pdf',
      category: 'Documents',
      description: 'Encrypted • AES-256-GCM • StrongBox',
      createdAt: DateTime(2024, 10, 20),
    ),
    VaultItem(
      id: '2',
      title: 'Bank Credentials',
      category: 'Credentials',
      description: 'Hardware-backed • Biometric required',
      createdAt: DateTime(2024, 10, 22),
    ),
    VaultItem(
      id: '3',
      title: 'Private Photos (12)',
      category: 'Photos',
      description: 'End-to-end encrypted • Zero-knowledge',
      createdAt: DateTime(2024, 10, 18),
    ),
    VaultItem(
      id: '4',
      title: 'Legal Documents',
      category: 'Documents',
      description: 'Encrypted vault • KeyStore protected',
      createdAt: DateTime(2024, 10, 15),
    ),
    VaultItem(
      id: '5',
      title: 'Recovery Keys',
      category: 'Credentials',
      description: 'Master seed • Never leaves device',
      createdAt: DateTime(2024, 10, 10),
    ),
  ];
}

/// Decoy data — benign fake content shown under duress
class DecoyData {
  static const fakeCallLogs = [
    {'name': 'Mom', 'time': 'Today 09:12', 'type': 'outgoing', 'duration': '2:34'},
    {'name': 'Ahmed - Work', 'time': 'Yesterday 16:45', 'type': 'incoming', 'duration': '5:12'},
    {'name': '+20 100 123 4567', 'time': 'Yesterday 11:20', 'type': 'missed', 'duration': ''},
    {'name': 'Sarah', 'time': 'Oct 24 14:30', 'type': 'outgoing', 'duration': '1:05'},
    {'name': 'Dr. Khaled', 'time': 'Oct 23 10:00', 'type': 'incoming', 'duration': '8:42'},
    {'name': 'Pizza Hut', 'time': 'Oct 22 19:15', 'type': 'outgoing', 'duration': '0:45'},
  ];

  static const fakePhotos = [
    {'title': 'Sunset at Nile', 'date': 'Oct 20, 2024'},
    {'title': 'Family Dinner', 'date': 'Oct 18, 2024'},
    {'title': 'Cats in Garden', 'date': 'Oct 15, 2024'},
    {'title': 'Beach Day', 'date': 'Oct 12, 2024'},
    {'title': 'Birthday Cake', 'date': 'Oct 08, 2024'},
    {'title': 'Graduation', 'date': 'Oct 05, 2024'},
  ];

  static const fakeNotes = [
    {'title': 'Grocery List', 'preview': 'Milk, bread, eggs, tomatoes...', 'date': 'Oct 24'},
    {'title': 'Meeting Notes', 'preview': 'Discuss Q4 roadmap with team...', 'date': 'Oct 22'},
    {'title': 'Recipe - Koshari', 'preview': 'Rice, lentils, pasta, tomato sauce...', 'date': 'Oct 20'},
    {'title': 'Workout Plan', 'preview': 'Mon: Chest, Tue: Back, Wed: Legs...', 'date': 'Oct 18'},
  ];
}
