import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class NotesDecoy extends StatefulWidget {
  const NotesDecoy({super.key});

  @override
  State<NotesDecoy> createState() => _NotesDecoyState();
}

class _NotesDecoyState extends State<NotesDecoy> {
  List<Map<String, String>> _notes = List.from(DecoyData.fakeNotes);

  void _addFakeNote() {
    setState(() {
      _notes.insert(0, {
        'title': 'New Note ${_notes.length + 1}',
        'preview': 'Tap to edit this note...',
        'date': 'Today',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppTheme.decoyMuted, size: 18),
                const SizedBox(width: 10),
                const Text('Search notes...', style: TextStyle(color: AppTheme.decoyMuted, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.tune, color: AppTheme.decoyMuted, size: 14),
                ),
              ],
            ),
          ),
        ),
        // Notes list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _notes.length,
            itemBuilder: (ctx, i) {
              final note = _notes[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _noteColor(i).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_noteIcon(i), color: _noteColor(i), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note['title']!, style: const TextStyle(color: AppTheme.decoyText, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(note['preview']!, style: const TextStyle(color: AppTheme.decoyMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(note['date']!, style: const TextStyle(color: AppTheme.decoyMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        const Icon(Icons.more_horiz, color: AppTheme.decoyMuted, size: 16),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Add button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addFakeNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.decoyAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Note', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Color _noteColor(int i) {
    const colors = [Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6)];
    return colors[i % colors.length];
  }

  IconData _noteIcon(int i) {
    const icons = [Icons.shopping_cart_outlined, Icons.work_outline, Icons.restaurant_outlined, Icons.fitness_center_outlined, Icons.lightbulb_outline];
    return icons[i % icons.length];
  }
}
