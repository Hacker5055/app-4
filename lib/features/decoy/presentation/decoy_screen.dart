import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'calculator_decoy.dart';
import 'notes_decoy.dart';
import 'gallery_decoy.dart';

/// Fake Decoy View — A realistic benign interface that deceives forced inspectors.
/// Appears as a normal utility app (Calculator + Notes + Gallery).
/// Zero indication that a vault ever existed. Seamless transition, no popups.
class DecoyScreen extends StatefulWidget {
  final VoidCallback onExitDecoy; // hidden exit: long-press title 5x
  final bool isMockMode;

  const DecoyScreen({super.key, required this.onExitDecoy, this.isMockMode = false});

  @override
  State<DecoyScreen> createState() => _DecoyScreenState();
}

class _DecoyScreenState extends State<DecoyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _secretTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleSecretTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _secretTapCount = 0;
    }
    _lastTapTime = now;
    _secretTapCount++;
    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      _showExitDialog();
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Decoy?', style: TextStyle(color: AppTheme.decoyText, fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Return to lock screen? This will require your PIN again.',
            style: TextStyle(color: AppTheme.decoyMuted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.decoyAccent),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onExitDecoy();
            },
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.decoyBg,
      appBar: AppBar(
        backgroundColor: AppTheme.decoyPanel,
        elevation: 0,
        title: GestureDetector(
          onTap: _handleSecretTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppTheme.decoyAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.calculate_outlined, color: AppTheme.decoyAccent, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Smart Tools', style: TextStyle(color: AppTheme.decoyText, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text('Calculator • Notes • Gallery', style: TextStyle(color: AppTheme.decoyMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: AppTheme.decoyMuted)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: AppTheme.decoyMuted)),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.decoyAccent,
          unselectedLabelColor: AppTheme.decoyMuted,
          indicatorColor: AppTheme.decoyAccent,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.calculate_outlined, size: 20), text: 'Calculator'),
            Tab(icon: Icon(Icons.note_outlined, size: 20), text: 'Notes'),
            Tab(icon: Icon(Icons.photo_library_outlined, size: 20), text: 'Gallery'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Subtle decoy banner — looks like an ad, not a security notice
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.lightbulb_outline, color: Color(0xFF3B82F6), size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tip: Swipe between tabs to explore', style: TextStyle(color: AppTheme.decoyText, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Your tools are ready to use', style: TextStyle(color: AppTheme.decoyMuted, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.close, color: AppTheme.decoyMuted, size: 16),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                CalculatorDecoy(),
                NotesDecoy(),
                GalleryDecoy(),
              ],
            ),
          ),
        ],
      ),
      // Bottom nav that looks like a normal utility app
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DecoyBottomItem(icon: Icons.home_outlined, label: 'Home', selected: true),
                _DecoyBottomItem(icon: Icons.history, label: 'History', selected: false),
                _DecoyBottomItem(icon: Icons.person_outline, label: 'Profile', selected: false),
                _DecoyBottomItem(icon: Icons.settings_outlined, label: 'Settings', selected: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecoyBottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _DecoyBottomItem({required this.icon, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? AppTheme.decoyAccent : AppTheme.decoyMuted, size: 22),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: selected ? AppTheme.decoyAccent : AppTheme.decoyMuted, fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}
