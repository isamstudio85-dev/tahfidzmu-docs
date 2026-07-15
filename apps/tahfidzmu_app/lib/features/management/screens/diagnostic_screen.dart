import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  bool _isFixing = false;

  Future<void> _fixDemoData(AppProvider provider) async {
    setState(() => _isFixing = true);
    try {
      final pid = provider.pesantrenId;
      if (pid == null) throw "Pesantren ID is NULL. Cannot fix.";

      // 1. Create a sample Musyrif
      final sample = MusyrifData(
        id: 'musyrif_demo_fix',
        nama: 'Musyrif Demo (Auto-Fix)',
        nip: '12345678',
        jabatan: 'Pembimbing Demo',
        lembaga: provider.pesantrenName,
      );

      await provider.getCollection('musyrif').doc(sample.id).set(sample.toJson());
      
      // 2. Ensure User Mapping for current user exists in this PID
      if (provider.currentUsername != null) {
        await provider.getCollection('user_mappings').doc(provider.currentUsername!).set({
          'linkedId': provider.linkedMusyrifId ?? 'admin',
          'role': 'admin',
          'pesantrenId': pid,
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data demo berhasil diperbaiki!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal fix: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isFixing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostik Sistem')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard('User Info', {
            'User ID': provider.currentUserId ?? 'null',
            'Role': provider.currentRole?.toString() ?? 'null',
            'Username': provider.currentUsername ?? 'null',
          }),
          const SizedBox(height: 16),
          _infoCard('Database Info', {
            'Pesantren ID': provider.pesantrenId ?? 'ROOT (Global)',
            'Santri Count': provider.santriList.length.toString(),
            'Musyrif Count': provider.musyrifList.length.toString(),
            'Halaqah Count': provider.halaqahList.length.toString(),
            'Santri Path': provider.getCollection('santri').path,
            'Musyrif Path': provider.getCollection('musyrif').path,
          }),
          const SizedBox(height: 16),
          _infoCard('Device/Session', {
            'Is Initializing': provider.isInitializing.toString(),
            'Surah List Loaded': provider.surahList.isNotEmpty.toString(),
          }),
          const SizedBox(height: 32),
          const Text(
            'LOG LISTENER TERAKHIR:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Periksa Logcat di Android Studio untuk melihat error parsing dokumen (jika ada).',
              style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => provider.setupFirestoreListeners(),
            child: const Text('Restart Semua Listener'),
          ),
          const SizedBox(height: 12),
          if (provider.pesantrenId == 'demo')
            OutlinedButton.icon(
              onPressed: _isFixing ? null : () => _fixDemoData(provider),
              icon: _isFixing 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.build_circle_outlined, color: Colors.orange),
              label: const Text('Perbaiki Data Pesantren DEMO', style: TextStyle(color: Colors.orange)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
            ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, Map<String, String> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen)),
            const Divider(),
            ...data.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
