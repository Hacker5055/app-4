import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/duress_service.dart';
import '../../config/presentation/duress_config_modal.dart';

/// Master Vault Screen — Shown only after Master PIN authentication.
/// Displays encrypted items, storage stats, duress configuration, and system status.
class VaultScreen extends StatefulWidget {
  final VoidCallback onLock;
  final DuressService duressService;

  const VaultScreen({super.key, required this.onLock, required this.duressService});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  bool _isMockMode = false;
  int _duressAction = AppConstants.duressActionDecoyAndPurge;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mock = await widget.duressService.isMockTestingMode();
    final action = await widget.duressService.getDuressAction();
    if (mounted) setState(() { _isMockMode = mock; _duressAction = action; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppTheme.neonGreen.withOpacity(0.05), Colors.transparent]),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──
                SliverAppBar(
                  backgroundColor: AppTheme.obsidian,
                  pinned: true,
                  expandedHeight: 0,
                  toolbarHeight: 64,
                  title: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.obsidianPanel,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.shield, color: AppTheme.neonGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CANARY VAULT', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                          Text('Hardware Encrypted • StrongBox', style: TextStyle(color: AppTheme.neonGreen, fontSize: 10, letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => _showDuressConfig(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.obsidianPanel, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.obsidianBorder)),
                        child: const Icon(Icons.security_outlined, color: AppTheme.textSecondary, size: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onLock,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3))),
                        child: const Icon(Icons.lock_outline, color: AppTheme.dangerRed, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // ── Mock Banner ──
                if (_isMockMode)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAmber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.warningAmber.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.science, color: AppTheme.warningAmber, size: 16),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('MOCK TESTING — Duress purges are simulated', style: TextStyle(color: AppTheme.warningAmber, fontSize: 12, fontWeight: FontWeight.w600))),
                          GestureDetector(
                            onTap: () => _showDuressConfig(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.warningAmber.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                              child: const Text('SETTINGS', style: TextStyle(color: AppTheme.warningAmber, fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Status Cards ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _StatusCard(icon: Icons.verified_user, label: 'VAULT STATUS', value: 'ENCRYPTED', subValue: 'AES-256-GCM • TEE', color: AppTheme.neonGreen)),
                            const SizedBox(width: 12),
                            Expanded(child: _StatusCard(icon: Icons.fingerprint, label: 'BIOMETRIC', value: 'HARDWARE', subValue: 'StrongBox Backed', color: AppTheme.infoBlue)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _StatusCard(icon: Icons.shield_outlined, label: 'DURESS PIN', value: 'ARMED', subValue: AppConstants.duressActionLabel(_duressAction).split(' — ').first, color: AppTheme.warningAmber)),
                            const SizedBox(width: 12),
                            Expanded(child: _StatusCard(icon: Icons.storage_outlined, label: 'ITEMS SECURED', value: '${MockVaultData.items.length}', subValue: 'Zero-knowledge', color: AppTheme.neonGreen)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Category Filter ──
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: ['All', ...AppConstants.vaultCategories].map((cat) {
                        final selected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.neonGreen : AppTheme.obsidianPanel,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? AppTheme.neonGreen : AppTheme.obsidianBorder),
                            ),
                            child: Center(
                              child: Text(cat,
                                  style: TextStyle(color: selected ? AppTheme.obsidian : AppTheme.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Vault Items ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final filtered = _selectedCategory == 'All'
                            ? MockVaultData.items
                            : MockVaultData.items.where((e) => e.category == _selectedCategory).toList();
                        if (index >= filtered.length) return null;
                        final item = filtered[index];
                        return _VaultItemCard(item: item);
                      },
                      childCount: (_selectedCategory == 'All'
                              ? MockVaultData.items
                              : MockVaultData.items.where((e) => e.category == _selectedCategory).toList())
                          .length,
                    ),
                  ),
                ),

                // ── Encryption Info Footer ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlowContainer(
                      glowColor: AppTheme.neonGreen.withOpacity(0.15),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: AppTheme.neonGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.lock_outline, color: AppTheme.neonGreen, size: 16),
                              ),
                              const SizedBox(width: 10),
                              const Text('End-to-End Encryption', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              const PulseIndicator(color: AppTheme.neonGreen, size: 8, label: 'ACTIVE'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'All vault contents are encrypted with AES-256-GCM using a hardware-backed key stored in Android StrongBox. Keys never leave the Trusted Execution Environment.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _InfoChip(icon: Icons.memory, label: 'TEE Isolated'),
                              const SizedBox(width: 8),
                              _InfoChip(icon: Icons.verified, label: 'StrongBox'),
                              const SizedBox(width: 8),
                              _InfoChip(icon: Icons.key, label: 'AES-256'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Quick Actions ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('QUICK ACTIONS',
                            style: TextStyle(color: AppTheme.textGhost, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _ActionButton(icon: Icons.add_photo_alternate_outlined, label: 'Add Photo', onTap: () {})),
                            const SizedBox(width: 12),
                            Expanded(child: _ActionButton(icon: Icons.note_add_outlined, label: 'Add Note', onTap: () {})),
                            const SizedBox(width: 12),
                            Expanded(child: _ActionButton(icon: Icons.key_outlined, label: 'Add Key', onTap: () {})),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // ── Security Footer ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          Container(width: 40, height: 1, color: AppTheme.obsidianBorder),
                          const SizedBox(height: 12),
                          const Text('PROTECTED BY CANARY DURESS LOCK',
                              style: TextStyle(color: AppTheme.textGhost, fontSize: 10, letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          const Text('Duress PIN triggers instant key purge — no recovery possible',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textGhost, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDuressConfig() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DuressConfigModal(
        duressService: widget.duressService,
        onSaved: () => _loadSettings(),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subValue;
  final Color color;

  const _StatusCard({required this.icon, required this.label, required this.value, required this.subValue, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.obsidianPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.obsidianBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppTheme.textGhost, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(subValue, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _VaultItemCard extends StatelessWidget {
  final VaultItem item;
  const _VaultItemCard({required this.item});

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Photos': return Icons.photo_library_outlined;
      case 'Documents': return Icons.description_outlined;
      case 'Credentials': return Icons.vpn_key_outlined;
      case 'Notes': return Icons.sticky_note_2_outlined;
      default: return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.obsidianPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.obsidianBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.obsidianLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.obsidianBorder),
            ),
            child: Icon(_categoryIcon(item.category), color: AppTheme.neonGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(item.description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.obsidianLight, borderRadius: BorderRadius.circular(4)),
                      child: Text(item.category, style: const TextStyle(color: AppTheme.textGhost, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.lock, color: AppTheme.neonGreen, size: 10),
                    const SizedBox(width: 4),
                    const Text('Encrypted', style: TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textGhost, size: 20),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.obsidianLight, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.obsidianBorder)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.neonGreen, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppTheme.obsidianPanel, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.obsidianBorder)),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
