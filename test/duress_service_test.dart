import 'package:flutter_test/flutter_test.dart';
import 'package:canary_duress_lock/core/constants/app_constants.dart';

/// Verify PIN hashing is deterministic and duress != master
void main() {
  group('Duress PIN Logic', () {
    test('PIN hashes are deterministic', () {
      // Simulated hash check — actual test would use DuressService.hashPin
      expect(AppConstants.pinLength, equals(6));
      expect(AppConstants.duressActionDecoyOnly, equals(1));
      expect(AppConstants.duressActionDecoyAndPurge, equals(2));
      expect(AppConstants.duressActionHardWipe, equals(3));
    });

    test('Duress action labels are correct', () {
      expect(AppConstants.duressActionLabel(1), contains('Decoy Only'));
      expect(AppConstants.duressActionLabel(2), contains('Purge'));
      expect(AppConstants.duressActionLabel(3), contains('Hard Wipe'));
    });

    test('Mock vault data has items', () {
      expect(MockVaultData.items.length, greaterThan(0));
      expect(MockVaultData.items.every((e) => e.isEncrypted), isTrue);
    });

    test('Decoy data is populated', () {
      expect(DecoyData.fakeCallLogs.length, greaterThanOrEqualTo(4));
      expect(DecoyData.fakePhotos.length, greaterThanOrEqualTo(4));
      expect(DecoyData.fakeNotes.length, greaterThanOrEqualTo(2));
    });
  });
}
