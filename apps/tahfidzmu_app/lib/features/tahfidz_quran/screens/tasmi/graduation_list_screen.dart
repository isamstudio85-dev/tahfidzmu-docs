import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';


class GraduationListScreen extends StatefulWidget {
  const GraduationListScreen({super.key});

  @override
  State<GraduationListScreen> createState() => _GraduationListScreenState();
}

class _GraduationListScreenState extends State<GraduationListScreen> {
  GraduationEvent? _selectedEvent;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final events = provider.graduationEvents;

    // Default selection
    if (_selectedEvent == null && events.isNotEmpty) {
      _selectedEvent = events.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Data Kelulusan Wisuda')),
      body: Column(
        children: [
          if (events.isNotEmpty) _buildEventFilter(events),
          Expanded(child: _buildList(provider)),
        ],
      ),
    );
  }

  Widget _buildEventFilter(List<GraduationEvent> events) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: events.map((e) {
          final isSelected = _selectedEvent?.id == e.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.title),
              selected: isSelected,
              onSelected: (v) => setState(() => _selectedEvent = e),
              selectedColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(AppProvider provider) {
    if (_selectedEvent == null) {
      return const Center(child: Text('Silahkan buat Agenda Wisuda di Pengaturan Sistem terlebih dahulu.'));
    }

    final List<(Santri, List<int>)> graduates = [];

    for (var s in provider.santriList) {
      final passedJuz = <int>{};
      for (var t in s.tasmiHistory) {
        // Matching by year (could be improved by matching specific event ID later)
        if (t.year == _selectedEvent!.year && t.isPass) {
          passedJuz.addAll(t.juzNumbers);
        }
      }
      if (passedJuz.isNotEmpty) {
        graduates.add((s, passedJuz.toList()..sort()));
      }
    }

    if (graduates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Belum ada santri lulus untuk ${_selectedEvent!.title}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: graduates.length,
      itemBuilder: (ctx, i) {
        final item = graduates[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            leading: AppAvatar(name: item.$1.name, imagePath: item.$1.photoPath, radius: 22),
            title: Text(item.$1.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Lulus Juz: ${item.$2.join(", ")}'),
            trailing: const Icon(Icons.verified_rounded, color: Colors.blue),
          ),
        );
      },
    );
  }
}
