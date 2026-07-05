import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/models/graduation_event.dart';
import 'package:tahfidz_app/models/graduation_registration.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class RegistrationManagementCard extends StatelessWidget {
  const RegistrationManagementCard({super.key, required this.event});
  final GraduationEvent event;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final regs = provider.graduationRegistrations.where((r) => r.eventId == event.id).toList();

    if (regs.isEmpty) {
      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: const Center(child: Text('Belum ada pendaftar.', style: TextStyle(color: Colors.grey))));
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: regs.map((r) {
          final s = provider.getSantriById(r.santriId);
          if (s == null) return const SizedBox.shrink();
          return ExpansionTile(
            leading: AppAvatar(name: s.name, imagePath: s.photoPath, radius: 18),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Status: ${r.status.name.toUpperCase()}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _regActionRow(context, 'Status Peserta', r.status.name.toUpperCase(),
                        () => _changeStatus(context, provider, r)),
                    const SizedBox(height: 12),
                    _regActionRow(
                        context,
                        'Pembayaran Daftar',
                        r.registrationPaymentStatus.name.replaceAll('_', ' ').toUpperCase(),
                        () => _changePayment(context, provider, r, true)),
                    const SizedBox(height: 12),
                    _regActionRow(
                        context,
                        'Pembayaran Wisuda',
                        r.graduationPaymentStatus.name.replaceAll('_', ' ').toUpperCase(),
                        () => _changePayment(context, provider, r, false)),
                  ],
                ),
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _regActionRow(BuildContext context, String label, String value, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration:
                BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(value,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ),
      ],
    );
  }

  void _changeStatus(BuildContext context, AppProvider p, GraduationRegistration r) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Ubah Status'),
        children: RegistrationStatus.values
            .map((s) => SimpleDialogOption(
                  onPressed: () {
                    p.updateGraduationRegistration(r.id, r.copyWith(status: s));
                    Navigator.pop(ctx);
                  },
                  child: Text(s.name.toUpperCase()),
                ))
            .toList(),
      ),
    );
  }

  void _changePayment(
      BuildContext context, AppProvider p, GraduationRegistration r, bool isRegistration) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Status Pembayaran'),
        children: PaymentStatus.values
            .map((s) => SimpleDialogOption(
                  onPressed: () {
                    if (isRegistration) {
                      p.updateGraduationRegistration(r.id, r.copyWith(registrationPaymentStatus: s));
                    } else {
                      p.updateGraduationRegistration(r.id, r.copyWith(graduationPaymentStatus: s));
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(s.name.replaceAll('_', ' ').toUpperCase()),
                ))
            .toList(),
      ),
    );
  }
}

class MusyrifViewCard extends StatelessWidget {
  const MusyrifViewCard({super.key, required this.event});
  final GraduationEvent event;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final regs = provider.graduationRegistrations.where((r) => r.eventId == event.id).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _musyrifRow(Icons.how_to_reg_rounded, 'Pendaftar Wisuda', '${regs.length} Santri'),
          const Divider(height: 32),
          _musyrifRow(
              Icons.fact_check_rounded,
              'Lulus Ujian (Calon)',
              '${provider.santriList.where((s) => s.tasmiHistory.any((t) => t.year == event.year && t.isPass)).length} Santri'),
        ],
      ),
    );
  }

  Widget _musyrifRow(IconData icon, String title, String count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration:
              BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      ],
    );
  }
}
