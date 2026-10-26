import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/duress_service.dart';
import 'pin_input_widget.dart';

/// Canary Lock Screen — The primary authentication gate.
/// Renders identically regardless of PIN type; duress detection is silent.
/// Features: stealth header, attempt counter, mock mode banner, seamless transition.
class LockScreen extends StatefulWidget {
  final VoidCallback onMasterUnlock;
  final VoidCallback onDuressTriggered;
  final DuressService duressService;

  const LockScreen({
    super.key,
    required this.onMasterUnlock,
    required this.onDuressTriggered,
    required this.duressService,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  bool _isError = false;
  bool _isLoading = false;
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  String? _errorMessage;
  bool _isMockMode = false;
  bool _showSetupSheet = false;

  // First-launch setup
  bool _isFirstLaunch = false;
  String _setupStep = 'master'; // master -> duress -> action -> done
  String? _pendingMasterPin;
  String? _pendingDuressPin;
  int _pendingAction = AppConstants.duressActionDecoyAndPurge;
  int _setupPinSession = 0;

  final GlobalKey<PinInputWidgetState> _gatePinKey = GlobalKey<PinInputWidgetState>();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _checkFirstLaunch();
    _loadMockMode();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    final hasPin = await widget.duressService.hasPinSetup();
    if (!hasPin) {
      setState(() {
        _isFirstLaunch = true;
        _showSetupSheet = true;
      });
    }
  }

  Future<void> _loadMockMode() async {
    final mock = await widget.duressService.isMockTestingMode();
    setState(() => _isMockMode = mock);
  }

  Future<void> _handlePinCompleted(String pin) async {
    if (_isLoading || _isLockedOut) return;

    // If in setup flow, handle setup
    if (_isFirstLaunch && _showSetupSheet) {
      _handleSetupPin(pin);
      return;
    }

    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    // Small delay for UX smoothness — also prevents timing attacks
    await Future.delayed(const Duration(milliseconds: 400));

    final result = await widget.duressService.verifyPin(pin);

    if (!mounted) return;

    switch (result) {
      case AuthResult.master:
        HapticFeedback.mediumImpact();
        _gatePinKey.currentState?.clearPin();
        setState(() => _isLoading = false);
        widget.onMasterUnlock();
        break;

      case AuthResult.duress:
        // CRITICAL: No visual distinction. Same loading, then execute duress.
        // The duress execution happens BEFORE navigation to decoy for data safety.
        final log = await widget.duressService.executeDuressSequence();
        if (!mounted) return;
        _gatePinKey.currentState?.clearPin();
        setState(() => _isLoading = false);

        // In mock mode, show the log before entering decoy
        if (_isMockMode) {
          _showMockDuressDialog(log);
        } else {
          widget.onDuressTriggered();
        }
        break;

      case AuthResult.invalid:
        final fails = await widget.duressService.failedAttempts();
        // Wipe the digits so the next attempt can be typed.
        _gatePinKey.currentState?.clearPin();
        setState(() {
          _isLoading = false;
          _isError = true;
          _failedAttempts = fails;
          _errorMessage = fails >= AppConstants.maxFailedAttempts
              ? 'Too many attempts. Locked for ${AppConstants.lockoutDurationMinutes} minutes.'
              : 'Incorrect PIN — ${AppConstants.maxFailedAttempts - fails} attempts remaining';
          if (fails >= AppConstants.maxFailedAttempts) _isLockedOut = true;
        });
        if (_isLockedOut) {
          Future.delayed(Duration(minutes: AppConstants.lockoutDurationMinutes), () {
            if (mounted) setState(() => _isLockedOut = false);
          });
        }
        // Clear error after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isError = false);
        });
        break;
    }
  }

  void _handleSetupPin(String pin) async {
    switch (_setupStep) {
      case 'master':
        setState(() {
          _pendingMasterPin = pin;
          _setupStep = 'duress';
          _setupPinSession++;
        });
        break;
      case 'duress':
        if (pin == _pendingMasterPin) {
          setState(() {
            _isError = true;
            _errorMessage = 'Duress PIN must be different from Master PIN';
            _setupPinSession++;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _isError = false);
          });
          return;
        }
        setState(() {
          _pendingDuressPin = pin;
          _setupStep = 'action';
          _setupPinSession++;
        });
        break;
    }
  }

  Future<void> _completeSetup() async {
    if (_pendingMasterPin == null || _pendingDuressPin == null) return;
    setState(() => _isLoading = true);
    await widget.duressService.setMasterPin(_pendingMasterPin!);
    await widget.duressService.setDuressPin(_pendingDuressPin!);
    await widget.duressService.setDuressAction(_pendingAction);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isFirstLaunch = false;
      _showSetupSheet = false;
      _setupStep = 'master';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vault initialized — Master & Duress PINs configured', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.obsidianPanel,
      ),
    );
  }

  void _showMockDuressDialog(DuressExecutionLog log) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.obsidianPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.warningAmber.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.bug_report, color: AppTheme.warningAmber, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('MOCK Duress Log', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.obsidianBorder),
                ),
                child: Text(
                  log.formatted,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontFamily: 'monospace', height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No data was deleted. This is mock mode for testing.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDuressTriggered();
            },
            child: const Text('Enter Decoy Mode', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: Stack(
        children: [
          // ── Ambient Glow ──
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.neonGreen.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.neonGreen.withOpacity(0.04), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Main Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Mock Testing Banner
                  if (_isMockMode)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAmber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.warningAmber.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.science_outlined, color: AppTheme.warningAmber, size: 16),
                          const SizedBox(width: 8),
                          const Text('MOCK TESTING MODE — No real data loss',
                              style: TextStyle(color: AppTheme.warningAmber, fontSize: 11, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showMockToggleSheet(),
                            child: const Text('CONFIG', style: TextStyle(color: AppTheme.warningAmber, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Header Shield ──
                  _buildHeader(),

                  const SizedBox(height: 32),

                  // ── PIN Dots + Keypad ──
                  if (!_showSetupSheet)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonGreen),
                                ),
                              )
                            else
                              PinInputWidget(
                                key: _gatePinKey,
                                pinLength: AppConstants.pinLength,
                                onCompleted: _handlePinCompleted,
                                enabled: !_isLockedOut && !_isLoading,
                                isError: _isError,
                              ),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 20, left: 32, right: 32),
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isLockedOut ? AppTheme.dangerRed : AppTheme.dangerRed.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (_failedAttempts > 0 && !_isLockedOut)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Failed attempts: $_failedAttempts/${AppConstants.maxFailedAttempts}',
                                  style: const TextStyle(color: AppTheme.textGhost, fontSize: 11),
                                ),
                              ),
                            const SizedBox(height: 24),
                            // Biometric hint
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.obsidianLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.obsidianBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fingerprint, color: AppTheme.textMuted, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Biometric available',
                                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Setup Flow ──
                  if (_showSetupSheet) _buildSetupFlow(),

                  // ── Footer ──
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 30, height: 1, color: AppTheme.obsidianBorder),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('CANARY DURESS LOCK v1.0',
                                  style: TextStyle(color: AppTheme.textGhost, fontSize: 10, letterSpacing: 1.5)),
                            ),
                            Container(width: 30, height: 1, color: AppTheme.obsidianBorder),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Hardware-Backed • StrongBox • TEE Isolated',
                            style: TextStyle(color: AppTheme.textGhost, fontSize: 10, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Shield Icon with glow
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [AppTheme.neonGreen.withOpacity(0.15), Colors.transparent]),
            border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3), width: 1.5),
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.obsidianPanel,
              border: Border.all(color: AppTheme.neonGreen.withOpacity(0.4)),
            ),
            child: const Icon(Icons.shield_outlined, color: AppTheme.neonGreen, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        const Text('CANARY', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 4)),
        const SizedBox(height: 2),
        const Text('DURESS LOCK', style: TextStyle(color: AppTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.obsidianPanel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.obsidianBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.neonGreen, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('SECURE VAULT LOCKED', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
        ),
        if (_isMockMode) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSetupFlow() {
    if (_setupStep == 'action') {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Text('Select Duress Response',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('What happens when duress PIN is entered?',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 20),
              ...[
                (1, 'Decoy Only', 'Show fake environment, keep data intact', Icons.visibility_outlined),
                (2, 'Decoy + Purge', 'Delete encryption keys & show decoy', Icons.delete_forever_outlined),
                (3, 'Hard Wipe', 'Factory reset via Device Admin', Icons.warning_amber_rounded),
              ].map((item) {
                final (value, title, desc, icon) = item;
                final selected = _pendingAction == value;
                return GestureDetector(
                  onTap: () => setState(() => _pendingAction = value),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.neonGreen.withOpacity(0.08) : AppTheme.obsidianPanel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppTheme.neonGreen : AppTheme.obsidianBorder, width: selected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(icon as IconData, color: selected ? AppTheme.neonGreen : AppTheme.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title as String, style: TextStyle(color: selected ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                              Text(desc as String, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (selected) const Icon(Icons.check_circle, color: AppTheme.neonGreen, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeSetup,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.obsidian))
                      : const Text('INITIALIZE SECURE VAULT'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _setupStep = 'duress';
                  _pendingDuressPin = null;
                  _setupPinSession++;
                  _isError = false;
                  _errorMessage = null;
                }),
                child: const Text('Back', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
      );
    }

    final isMaster = _setupStep == 'master';
    return Expanded(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neonGreen.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppTheme.neonGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(isMaster ? '1' : '2', style: const TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isMaster ? 'Set Master PIN (Real Vault)' : 'Set Duress PIN (Decoy Trigger)',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(isMaster ? 'Unlocks your encrypted vault' : 'Triggers decoy & purge sequence',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PinInputWidget(
            key: ValueKey<String>('setup_${_setupStep}_$_setupPinSession'),
            pinLength: AppConstants.pinLength,
            onCompleted: _handleSetupPin,
            isError: _isError,
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  void _showMockToggleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.obsidianPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.obsidianBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Mock Testing Mode', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('When enabled, duress triggers are simulated — no real data is deleted. Use this to verify the flow in emulators.',
                textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            SwitchListTile(
              value: _isMockMode,
              onChanged: (v) async {
                await widget.duressService.setMockTestingMode(v);
                setState(() => _isMockMode = v);
                if (mounted) Navigator.pop(ctx);
              },
              title: const Text('Enable Mock Mode', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(_isMockMode ? 'ON — Safe for testing' : 'OFF — Real purge will execute',
                  style: TextStyle(color: _isMockMode ? AppTheme.warningAmber : AppTheme.dangerRed, fontSize: 12)),
              activeColor: AppTheme.warningAmber,
            ),
          ],
        ),
      ),
    );
  }
}
