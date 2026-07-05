import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/graduation_event.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/features/management/screens/graduation_event_form_screen.dart';

class GraduationEventListScreen extends StatelessWidget {
  const GraduationEventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Wisuda'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final events = provider.graduationEvents;
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Belum ada agenda wisuda', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (ctx, i) {
              final e = events[i];
              return _EventCard(event: e);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GraduationEventFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Agenda'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final GraduationEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _infoRow(Icons.calendar_today, 'Tahun ${event.year}'),
            _infoRow(Icons.settings_suggest, event.method),
            _infoRow(Icons.event_repeat, '${event.sessionsCount} Kali Duduk'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => GraduationEventFormScreen(existing: event)));
            } else if (val == 'delete') {
              _confirmDelete(context);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Agenda?'),
        content: const Text('Data agenda wisuda ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().removeGraduationEvent(event.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
