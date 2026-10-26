import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class GalleryDecoy extends StatelessWidget {
  const GalleryDecoy({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: ['All Photos', 'Camera', 'Screenshots', 'Downloads', 'Favorites'].map((label) {
              final selected = label == 'All Photos';
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.decoyAccent : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? AppTheme.decoyAccent : const Color(0xFFE2E8F0)),
                ),
                child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.decoyText, fontSize: 12, fontWeight: FontWeight.w600))),
              );
            }).toList(),
          ),
        ),
        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text('1,248 photos • 12 videos', style: TextStyle(color: AppTheme.decoyMuted, fontSize: 12)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: const Row(
                  children: [
                    Icon(Icons.grid_view, color: AppTheme.decoyMuted, size: 14),
                    SizedBox(width: 4),
                    Text('Grid', style: TextStyle(color: AppTheme.decoyMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Photo grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: DecoyData.fakePhotos.length + 12,
            itemBuilder: (ctx, i) {
              if (i < DecoyData.fakePhotos.length) {
                final photo = DecoyData.fakePhotos[i];
                return _PhotoTile(title: photo['title']!, date: photo['date']!, index: i);
              }
              // Generic photo placeholders
              return _PhotoTile(title: 'IMG_${1000 + i}.jpg', date: 'Oct ${10 + (i % 15)}, 2024', index: i);
            },
          ),
        ),
        // Fake call logs section — realistic phone inspector bait
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.call_outlined, color: Color(0xFF3B82F6), size: 14),
                  ),
                  const SizedBox(width: 8),
                  const Text('Recent Calls', style: TextStyle(color: AppTheme.decoyText, fontSize: 13, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Text('View all', style: TextStyle(color: AppTheme.decoyAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              ...DecoyData.fakeCallLogs.take(4).map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                      child: Icon(
                        log['type'] == 'missed' ? Icons.call_received : log['type'] == 'incoming' ? Icons.call_received : Icons.call_made,
                        color: log['type'] == 'missed' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log['name']!, style: const TextStyle(color: AppTheme.decoyText, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(log['time']!, style: const TextStyle(color: AppTheme.decoyMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (log['duration']!.isNotEmpty)
                      Text(log['duration']!, style: const TextStyle(color: AppTheme.decoyMuted, fontSize: 11)),
                    const SizedBox(width: 8),
                    const Icon(Icons.info_outline, color: AppTheme.decoyMuted, size: 16),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String title;
  final String date;
  final int index;

  const _PhotoTile({required this.title, required this.date, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFEF3C7), const Color(0xFFD1FAE5), const Color(0xFFDBEAFE),
      const Color(0xFFFCE7F3), const Color(0xFFE0E7FF), const Color(0xFFFED7AA),
    ];
    final icons = [
      Icons.wb_sunny_outlined, Icons.people_outline, Icons.pets_outlined,
      Icons.beach_access_outlined, Icons.cake_outlined, Icons.school_outlined,
      Icons.landscape_outlined, Icons.favorite_outline, Icons.celebration_outlined,
    ];
    return Container(
      decoration: BoxDecoration(
        color: colors[index % colors.length],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icons[index % icons.length], color: AppTheme.decoyMuted, size: 28),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.decoyText, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(date, style: const TextStyle(color: AppTheme.decoyMuted, fontSize: 9)),
        ],
      ),
    );
  }
}
