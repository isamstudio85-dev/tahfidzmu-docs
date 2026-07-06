import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/app_provider.dart';
import 'register_pesantren_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  final AppProvider provider;
  const SuperAdminDashboard({super.key, required this.provider});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  bool _isLoading = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    await widget.provider.logout();
  }

  void _showEditDialog(String id, String currentNama, String? logoUrl) {
    final nameCtrl = TextEditingController(text: currentNama);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Ubah Nama Pesantren', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Pesantren',
            prefixIcon: Icon(Icons.school_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await widget.provider.updatePesantren(id, nama: nameCtrl.text.trim(), logoPath: logoUrl);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Nama pesantren berhasil diubah')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Gagal mengubah: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(String id, String nama, String currentTier, DateTime activeUntil, String currentStatus) {
    String selectedTier = currentTier;
    String selectedStatus = currentStatus;
    DateTime selectedDate = activeUntil;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Kelola Langganan\n$nama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paket Langganan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                DropdownButton<String>(
                  value: selectedTier,
                  isExpanded: true,
                  items: ['Trial', 'Premium Bulanan', 'Premium Tahunan'].map((tier) {
                    return DropdownMenuItem<String>(value: tier, child: Text(tier));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedTier = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Status Akses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem<String>(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem<String>(value: 'suspended', child: Text('Ditangguhkan (Blokir)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Masa Berlaku s/d', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month_rounded, color: Colors.green),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.green,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await widget.provider.updateSubscription(
                      id,
                      tier: selectedTier,
                      activeUntil: selectedDate,
                      status: selectedStatus,
                    );
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Langganan berhasil diperbarui')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(String id, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Pesantren?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$nama"? Semua data santri, musyrif, dan konfigurasi akan dihapus secara permanen dari server.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await widget.provider.deletePesantren(id);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Pesantren berhasil dihapus')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text(
          'Super Admin Portal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _isLoading ? null : _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.provider.firestore.collection('pesantren').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_rounded, size: 80, color: Colors.green.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada pesantren terdaftar.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang, Owner',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola pendaftaran, paket langganan & akses pesantren.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      label: Text(
                        'Total Pesantren: ${docs.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau kode pesantren...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.green),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final filtered = _searchQuery.isEmpty
                        ? docs
                        : docs.where((d) {
                            final nm = (d.data()['nama'] ?? '').toString().toLowerCase();
                            final kd = d.id.toLowerCase();
                            return nm.contains(_searchQuery) || kd.contains(_searchQuery);
                          }).toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Pesantren tidak ditemukan.', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final docSnap = filtered[index];
                        final data = docSnap.data();
                        final String nama = data['nama'] ?? 'Pesantren';
                        final String id = docSnap.id;
                        final String status = data['status'] ?? 'active';
                    
                    final activeUntilRaw = data['activeUntil'];
                    DateTime? activeUntil;
                    if (activeUntilRaw is Timestamp) {
                      activeUntil = activeUntilRaw.toDate();
                    }
                    final String activeUntilStr = activeUntil != null 
                        ? "${activeUntil.day.toString().padLeft(2, '0')}-${activeUntil.month.toString().padLeft(2, '0')}-${activeUntil.year}"
                        : "-";
                    final String subscriptionTier = data['subscriptionTier'] ?? 'Trial';

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => widget.provider.loginAsTenantAdmin(id, nama),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  image: data['logoUrl'] != null
                                      ? DecorationImage(
                                          image: NetworkImage(data['logoUrl'] as String),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: data['logoUrl'] == null
                                    ? const Icon(Icons.school_rounded, color: Colors.green)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nama,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: status == 'active' ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        Text(
                                          'Kode: $id',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.green.shade200),
                                          ),
                                          child: Text(
                                            subscriptionTier,
                                            style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Aktif s/d: $activeUntilStr',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditDialog(id, nama, data['logoUrl'] as String?);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirm(id, nama);
                                  } else if (value == 'subscription') {
                                    final currentActiveUntil = activeUntil ?? DateTime.now();
                                    _showSubscriptionDialog(id, nama, subscriptionTier, currentActiveUntil, status);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Ubah Nama'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'subscription',
                                    child: Row(
                                      children: [
                                        Icon(Icons.payment_rounded, size: 18, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Kelola Langganan'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Hapus', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      );
                    },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterPesantrenScreen(provider: widget.provider),
            ),
          );
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Pesantren Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
