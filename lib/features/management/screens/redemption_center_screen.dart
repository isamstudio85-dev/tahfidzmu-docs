import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/voucher_ticket.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:intl/intl.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/qr_scanner_screen.dart';

class RedemptionCenterScreen extends StatefulWidget {
  const RedemptionCenterScreen({super.key});

  @override
  State<RedemptionCenterScreen> createState() => _RedemptionCenterScreenState();
}

class _RedemptionCenterScreenState extends State<RedemptionCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final pendingVouchers = provider.voucherList.where((v) => v.status == VoucherStatus.pending).toList();
    final redeemedVouchers = provider.voucherList.where((v) => v.status == VoucherStatus.redeemed).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'PUSAT PENUKARAN',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'AKTIF (${pendingVouchers.length})'),
            Tab(text: 'RIWAYAT (${redeemedVouchers.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _VoucherList(vouchers: pendingVouchers, isHistory: false),
          _VoucherList(vouchers: redeemedVouchers, isHistory: true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scanVoucher(context, provider),
        label: const Text('SCAN TIKET', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.qr_code_scanner_rounded),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Future<void> _scanVoucher(BuildContext context, AppProvider provider) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen(returnRaw: true)),
    );

    if (result != null) {
      final voucher = provider.voucherList.where((v) => v.id == result).firstOrNull;
      if (voucher != null) {
        if (voucher.status == VoucherStatus.redeemed) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voucher ini sudah pernah dicairkan!'), backgroundColor: Colors.red),
            );
          }
        } else {
          if (context.mounted) {
            _confirmRedeem(context, provider, voucher);
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voucher tidak ditemukan dalam sistem.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _confirmRedeem(BuildContext context, AppProvider provider, VoucherTicket voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cairkan Voucher?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Santri: ${voucher.santriName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Hadiah: ${voucher.rewardName}'),
            const SizedBox(height: 16),
            const Text('Pastikan hadiah fisik sudah diberikan kepada santri sebelum menekan tombol Cairkan.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.redeemVoucher(voucher.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voucher berhasil dicairkan!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('CAIRKAN'),
          ),
        ],
      ),
    );
  }
}

class _VoucherList extends StatelessWidget {
  final List<VoucherTicket> vouchers;
  final bool isHistory;

  const _VoucherList({required this.vouchers, required this.isHistory});

  @override
  Widget build(BuildContext context) {
    if (vouchers.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => await context.read<AppProvider>().setupFirestoreListeners(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      isHistory ? 'Belum ada riwayat penukaran' : 'Tidak ada voucher aktif saat ini',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await context.read<AppProvider>().setupFirestoreListeners(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
        final v = vouchers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isHistory ? Colors.grey.shade100 : Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHistory ? Icons.check_circle_rounded : Icons.confirmation_number_rounded,
                color: isHistory ? Colors.grey : Colors.orange,
              ),
            ),
            title: Text(v.rewardName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Santri: ${v.santriName}', style: const TextStyle(fontSize: 12)),
                Text(
                  '${isHistory ? "Dicairkan" : "Dibeli"}: ${DateFormat('dd MMM, HH:mm').format(isHistory ? (v.redeemedDate ?? v.purchaseDate) : v.purchaseDate)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            trailing: isHistory 
              ? const Icon(Icons.chevron_right_rounded, color: Colors.grey)
              : FilledButton(
                  onPressed: () => _confirmRedeemDirect(context, v),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('CAIRKAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
          ),
        );
      },
    ),
  );
}

  void _confirmRedeemDirect(BuildContext context, VoucherTicket voucher) {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cairkan Voucher?'),
        content: Text('Tandai "${voucher.rewardName}" untuk ${voucher.santriName} sebagai sudah diberikan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.redeemVoucher(voucher.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voucher berhasil dicairkan!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('CAIRKAN'),
          ),
        ],
      ),
    );
  }
}
