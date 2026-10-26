import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/duress_service.dart';

/// Duress Action Configuration Panel — bottom sheet for setting duress behavior.
/// Includes: PIN change, action selector, device admin, mock mode, audit log.
class DuressConfigModal extends StatefulWidget {
  final DuressService duressService;
  final VoidCallback onSaved;

  const DuressConfigModal({super.key, required this.duressService, required this.onSaved});

  @override
  State<DuressConfigModal> createState() => _DuressConfigModalState();
}

class _DuressConfigModalState extends State<DuressConfigModal> {
  int _selectedAction = AppConstants.duressActionDecoyAndPurge;
  bool _isMockMode = false;
  bool _isAdminActive = false;
  bool _biometricEnabled = false;
  bool _isSaving = false;

  final _masterPinController = TextEditingController();
  final _duressPinController = TextEditingController();
  bool _showPinFields = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final action = await widget.duressService.getDuressAction();
    final mock = await widget.duressService.isMockTestingMode();
    if (mounted) setState(() { _selectedAction = action; _isMockMode = mock; });
  }

  @override
  void dispose() {
    _masterPinController.dispose();
    _duressPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.obsidianPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.obsidianBorder, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.neonGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.security, color: AppTheme.neonGreen, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Duress Configuration', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('Configure emergency response actions', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.obsidianLight, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Response Action Selector ──
                const Text('DURESS RESPONSE ACTION', style: TextStyle(color: AppTheme.textGhost, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _ActionOption(
                  value: AppConstants.duressActionDecoyOnly,
                  selected: _selectedAction,
                  icon: Icons.visibility_outlined,
                  title: 'Decoy Only',
                  description: 'Show fake environment. Vault data remains intact but hidden.',
                  riskLabel: 'LOW RISK',
                  riskColor: AppTheme.infoBlue,
                  onTap: () => setState(() => _selectedAction = AppConstants.duressActionDecoyOnly),
                ),
                _ActionOption(
                  value: AppConstants.duressActionDecoyAndPurge,
                  selected: _selectedAction,
                  icon: Icons.delete_forever_outlined,
                  title: 'Decoy + Purge Keys',
                  description: 'Delete KeyStore keys & show decoy. Data unrecoverable without backup.',
                  riskLabel: 'RECOMMENDED',
                  riskColor: AppTheme.neonGreen,
                  onTap: () => setState(() => _selectedAction = AppConstants.duressActionDecoyAndPurge),
                ),
                _ActionOption(
                  value: AppConstants.duressActionHardWipe,
                  selected: _selectedAction,
                  icon: Icons.warning_amber_rounded,
                  title: 'Hard Wipe Device',
                  description: 'Factory reset via Device Admin. Requires BIND_DEVICE_ADMIN permission.',
                  riskLabel: 'DESTRUCTIVE',
                  riskColor: AppTheme.dangerRed,
                  onTap: () => setState(() => _selectedAction = AppConstants.duressActionHardWipe),
                ),

                const SizedBox(height: 24),

                // ── PIN Management ──
                GestureDetector(
                  onTap: () => setState(() => _showPinFields = !_showPinFields),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.obsidianLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.obsidianBorder)),
                    child: Row(
                      children: [
                        const Icon(Icons.key_outlined, color: AppTheme.neonGreen, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Change PINs', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
                        Icon(_showPinFields ? Icons.expand_less : Icons.expand_more, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
                if (_showPinFields) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _masterPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary, letterSpacing: 8),
                    decoration: const InputDecoration(hintText: 'New Master PIN (6 digits)', counterText: ''),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _duressPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary, letterSpacing: 8),
                    decoration: const InputDecoration(hintText: 'New Duress PIN (6 digits)', counterText: ''),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _updatePins,
                      child: const Text('Update PINs'),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Toggles ──
                const Text('SECURITY OPTIONS', style: TextStyle(color: AppTheme.textGhost, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 12),

                _ToggleTile(
                  icon: Icons.science_outlined,
                  title: 'Mock Testing Mode',
                  subtitle: _isMockMode ? 'ON — Purges are simulated' : 'OFF — Real purge executes',
                  value: _isMockMode,
                  activeColor: AppTheme.warningAmber,
                  onChanged: (v) async {
                    await widget.duressService.setMockTestingMode(v);
                    setState(() => _isMockMode = v);
                  },
                ),
                const SizedBox(height: 10),
                _ToggleTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Device Admin (Hard Wipe)',
                  subtitle: _isAdminActive ? 'Active — wipe authorized' : 'Inactive — tap to request',
                  value: _isAdminActive,
                  activeColor: AppTheme.neonGreen,
                  onChanged: (v) {
                    setState(() => _isAdminActive = v);
                    if (v) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device Admin request sent — check system prompt'), backgroundColor: AppTheme.obsidianLight));
                  },
                ),
                const SizedBox(height: 10),
                _ToggleTile(
                  icon: Icons.fingerprint,
                  title: 'Biometric Unlock',
                  subtitle: 'Use fingerprint / face for vault access',
                  value: _biometricEnabled,
                  activeColor: AppTheme.neonGreen,
                  onChanged: (v) => setState(() => _biometricEnabled = v),
                ),

                const SizedBox(height: 24),

                // ── Warning Box ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dangerRed.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Irreversible Action Warning', style: TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Purge operations permanently delete encryption keys from StrongBox. Without a backup, vault data cannot be recovered.',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Save Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.obsidian))
                        : const Text('SAVE CONFIGURATION', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: Text('Canary Duress Lock • TEE Isolated • StrongBox Backed',
                      style: TextStyle(color: AppTheme.textGhost, fontSize: 10, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updatePins() async {
    final master = _masterPinController.text.trim();
    final duress = _duressPinController.text.trim();
    if (master.isNotEmpty) {
      if (master.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Master PIN must be 6 digits')));
        return;
      }
      await widget.duressService.setMasterPin(master);
    }
    if (duress.isNotEmpty) {
      if (duress.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duress PIN must be 6 digits')));
        return;
      }
      if (duress == master && master.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duress PIN must differ from Master PIN')));
        return;
      }
      await widget.duressService.setDuressPin(duress);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs updated'), backgroundColor: AppTheme.obsidianLight));
      setState(() => _showPinFields = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    await widget.duressService.setDuressAction(_selectedAction);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onSaved();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved — duress response updated', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.obsidianPanel),
    );
  }
}

class _ActionOption extends StatelessWidget {
  final int value;
  final int selected;
  final IconData icon;
  final String title;
  final String description;
  final String riskLabel;
  final Color riskColor;
  final VoidCallback onTap;

  const _ActionOption({
    required this.value,
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.riskLabel,
    required this.riskColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? riskColor.withOpacity(0.06) : AppTheme.obsidianLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? riskColor : AppTheme.obsidianBorder, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: (isSelected ? riskColor : AppTheme.textMuted).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: isSelected ? riskColor : AppTheme.textMuted, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: riskColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                        child: Text(riskLabel, style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.3)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: riskColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.activeColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.obsidianLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.obsidianBorder)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: (value ? activeColor : AppTheme.textMuted).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: value ? activeColor : AppTheme.textMuted, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: value ? activeColor : AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: activeColor),
        ],
      ),
    );
  }
}
