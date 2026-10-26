import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/services/duress_service.dart';
import 'core/platform/method_channel_service.dart';
import 'features/auth/presentation/lock_screen.dart';
import 'features/vault/presentation/vault_screen.dart';
import 'features/decoy/presentation/decoy_screen.dart';

/// Canary Duress Lock — Root App Controller
/// Manages authentication state transitions with zero-latency duress handoff.
class CanaryApp extends StatefulWidget {
  const CanaryApp({super.key});

  @override
  State<CanaryApp> createState() => _CanaryAppState();
}

enum AppState { locked, vault, decoy }

class _CanaryAppState extends State<CanaryApp> {
  AppState _state = AppState.locked;
  late final DuressService _duressService;
  late final MethodChannelService _native;

  @override
  void initState() {
    super.initState();
    _native = MethodChannelService();
    _duressService = DuressService(_native);
  }

  void _onMasterUnlock() {
    setState(() => _state = AppState.vault);
  }

  void _onDuressTriggered() {
    setState(() => _state = AppState.decoy);
  }

  void _onLock() {
    setState(() => _state = AppState.locked);
  }

  void _onExitDecoy() {
    setState(() => _state = AppState.locked);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canary Duress Lock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkStealthTheme,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_state) {
      case AppState.locked:
        return LockScreen(
          key: const ValueKey('lock'),
          duressService: _duressService,
          onMasterUnlock: _onMasterUnlock,
          onDuressTriggered: _onDuressTriggered,
        );
      case AppState.vault:
        return VaultScreen(
          key: const ValueKey('vault'),
          duressService: _duressService,
          onLock: _onLock,
        );
      case AppState.decoy:
        return FutureBuilder<bool>(
          future: _duressService.isMockTestingMode(),
          builder: (ctx, snap) => DecoyScreen(
            key: const ValueKey('decoy'),
            onExitDecoy: _onExitDecoy,
            isMockMode: snap.data ?? false,
          ),
        );
    }
  }
}
