import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/voucher_ticket.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:intl/intl.dart';

class MyVouchersScreen extends StatelessWidget {
  const MyVouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myVouchers = provider.voucherList
        .where((v) => v.santriId == provider.linkedSantriId)
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('VOUCHER SAYA'),
        centerTitle: true,
      ),
      body: myVouchers.isEmpty
          ? _emptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: myVouchers.length,
              itemBuilder: (context, index) {
                return _VoucherCard(ticket: myVouchers[index], isDark: isDark);
              },
            ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, 
              size: 80, color: isDark ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'Belum ada voucher aktif',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tukarkan koinmu di Toko Reward!',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final VoucherTicket ticket;
  final bool isDark;

  const _VoucherCard({required this.ticket, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPending = ticket.status == VoucherStatus.pending;
    final color = isPending ? Colors.orange : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          child: Column(
            children: [
              // Ticket Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: color.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TIKET DIGITAL',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1,
                        color: color,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ticket.status.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.rewardName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dibeli: ${DateFormat('dd MMM yyyy, HH:mm').format(ticket.purchaseDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (ticket.status == VoucherStatus.redeemed && ticket.redeemedDate != null) ...[
                             const SizedBox(height: 4),
                             Text(
                              'Dicairkan: ${DateFormat('dd MMM yyyy, HH:mm').format(ticket.redeemedDate!)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isPending)
                      GestureDetector(
                        onTap: () => _showQrDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: ticket.id,
                            version: QrVersions.auto,
                            size: 60.0,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Perforated edge effect
              Row(
                children: List.generate(
                  20,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                  ),
                ),
              ),
              
              if (isPending)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Tunjukkan QR ini ke Musyrif untuk mencairkan hadiah',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                    ),
                  ),
                )
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SCAN UNTUK CAIRKAN',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: ticket.id,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 20),
            Text(
              ticket.rewardName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Berikan HP ini ke Musyrif atau Admin',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
