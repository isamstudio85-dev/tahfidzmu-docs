import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/models/tasmi_record.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/scoring_utils.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_widgets.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/continuation_dialog.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/verification_gate.dart';
import 'package:tahfidz_app/features/management/screens/santri_form_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_detail_screen.dart';

class SantriDetailScreen extends StatefulWidget {
  const SantriDetailScreen({super.key, required this.santriId});
  final String santriId;

  @override
  State<SantriDetailScreen> createState() => _SantriDetailScreenState();
}

class _SantriDetailScreenState extends State<SantriDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().listenToActiveSantriHistory(widget.santriId);
      }
    });
  }

  @override
  void dispose() {
    context.read<AppProvider>().stopListeningToActiveSantriHistory(widget.santriId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final santri = provider.getSantriById(widget.santriId);
        if (santri == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Santri')),
            body: const Center(child: Text('Santri tidak ditemukan')),
          );
        }

        final avg = santri.averageScore;
        final stars = santri.overallStarCount;
        final grade = ScoringUtils.scoreToGrade(avg);
        final halaqah = provider.getHalaqahById(santri.halaqahId);
        final isAdmin = provider.isAdmin;

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth > 700;

            if (isTablet) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Detail Santri'),
                  actions: [
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Profil',
                        onPressed: () async {
                          final verified = await VerificationGate.show(
                            context: context,
                            expectedSantri: santri,
                          );
                          if (verified != null && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SantriFormScreen(existing: santri)),
                            );
                          }
                        },
                      ),
                  ],
                ),
                floatingActionButton: provider.isMusyrif
                    ? FloatingActionButton.extended(
                        heroTag: 'fab_detail_setoran',
                        onPressed: () => showSetoranOptions(context, santri),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Mulai Setoran'),
                      )
                    : null,
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN: Profile & QR
                    Expanded(
                      flex: 4,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          _ProfileHeader(
                            name: santri.name,
                            subtitle: '${santri.kelas ?? 'Tanpa Kelas'} • ${halaqah?.nama ?? 'Tanpa Halaqah'}',
                            photoPath: santri.photoPath,
                            extra: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                StarRatingWidget(rating: stars, size: 14),
                                GradeBadgeWidget(gradeName: grade, stars: stars),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _MiniDigitalCard(santri: santri),
                          const SizedBox(height: 24),
                          _sectionHeader('Informasi Personal'),
                          _infoCard([
                            _infoRow(Icons.meeting_room_rounded, 'Kelas', santri.kelas ?? '-'),
                            _infoRow(Icons.badge_outlined, 'NIS', santri.nis ?? '-'),
                            _infoRow(Icons.cake_rounded, 'Tanggal Lahir', santri.tanggalLahir ?? '-'),
                            _infoRow(Icons.male_rounded, 'Jenis Kelamin', santri.jenisKelamin == 'P' ? 'Perempuan' : 'Laki-laki'),
                            _infoRow(Icons.history_edu_rounded, 'Hafalan Awal', santri.initialMemorizedJuz.isEmpty ? 'Mulai dari Nol' : 'Sudah hafal Juz: ${santri.initialMemorizedJuz.join(', ')}'),
                            _infoRow(Icons.email_outlined, 'Email', santri.email ?? '-'),
                            _infoRow(Icons.family_restroom_outlined, 'Orang Tua', santri.namaOrangTua ?? '-'),
                            _infoRow(Icons.phone_outlined, 'No. HP Wali', santri.nomorHpWali ?? '-'),
                            _infoRow(Icons.flag_outlined, 'Target Hafalan', santri.targetHafalan ?? '-'),
                            _infoRow(Icons.info_outline, 'Status Akun', santri.isAktif ? 'Aktif' : 'Non-aktif',
                                valueColor: santri.isAktif ? AppTheme.primaryGreen : Colors.grey),
                          ]),
                        ],
                      ),
                    ),
                    VerticalDivider(width: 1, color: Colors.grey.shade200),
                    // RIGHT COLUMN: Hafalan History
                    Expanded(
                      flex: 6,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          _sectionHeader('Statistik Perkembangan'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statItem('Rata-rata', avg.toStringAsFixed(0), Icons.bar_chart_rounded, AppTheme.gold),
                              const SizedBox(width: 12),
                              _statItem('Total Hafalan', '${santri.estimatedJuz.toStringAsFixed(1)} Juz', Icons.library_books_rounded, Colors.purple.shade600),
                              const SizedBox(width: 12),
                              _statItem('Ayat Lulus', '${santri.totalZiyadahAyahs + santri.totalMurojaahAyahs}', Icons.check_circle_outline_rounded, Colors.green),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Ujian Tasmi'
                          if (provider.isModuleActive('graduation') &&
                              provider.graduationEvents.any((e) => e.isPublished)) ...[
                            _sectionHeader('Ujian Tasmi\' / Wisuda'),
                            if (santri.tasmiHistory.isEmpty)
                              _emptyHistory('Belum ada riwayat ujian Tasmi\'')
                            else
                              ...santri.tasmiHistory.reversed.map(
                                (t) => _TasmiHistoryTile(record: t),
                              ),
                            const SizedBox(height: 32),
                          ],

                          // Riwayat Setoran
                          _sectionHeader('Riwayat Setoran'),
                          if (santri.setoranHistory.isEmpty)
                            _emptyHistory('Belum ada riwayat setoran')
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                childAspectRatio: 4.5,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: santri.setoranHistory.length,
                              itemBuilder: (ctx, i) {
                                final r = santri.setoranHistory.reversed.toList()[i];
                                return _SetoranHistoryTile(record: r, santri: santri);
                              },
                            ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Detail Santri'),
                  actions: [
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Profil',
                        onPressed: () async {
                          final verified = await VerificationGate.show(
                            context: context,
                            expectedSantri: santri,
                          );
                          if (verified != null && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SantriFormScreen(existing: santri)),
                            );
                          }
                        },
                      ),
                  ],
                ),
                floatingActionButton: provider.isMusyrif
                    ? FloatingActionButton.extended(
                        heroTag: 'fab_detail_setoran',
                        onPressed: () => showSetoranOptions(context, santri),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Mulai Setoran'),
                      )
                    : null,
                body: Column(
                  children: [
                    // 1. Unified Profile Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _ProfileHeader(
                        name: santri.name,
                        subtitle: '${santri.kelas ?? 'Tanpa Kelas'} • ${halaqah?.nama ?? 'Tanpa Halaqah'}',
                        photoPath: santri.photoPath,
                        extra: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StarRatingWidget(rating: stars, size: 14),
                            GradeBadgeWidget(gradeName: grade, stars: stars),
                          ],
                        ),
                      ),
                    ),

                    TabBar(
                      tabs: const [
                        Tab(text: 'Hafalan'),
                        Tab(text: 'Profil & QR'),
                      ],
                      labelColor: AppTheme.primaryGreen,
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorColor: AppTheme.primaryGreen,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                    ),

                    Expanded(
                      child: TabBarView(
                        children: [
                          // TAB 1: PERKEMBANGAN HAFALAN
                          ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildProgressCard(santri),
                              const SizedBox(height: 24),
                              
                              _sectionHeader('Statistik Detail'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _statItem('Rata-rata', avg.toStringAsFixed(0), Icons.bar_chart_rounded, AppTheme.gold),
                                  const SizedBox(width: 12),
                                  _statItem('Total Hafalan', '${santri.estimatedJuz.toStringAsFixed(1)} Juz', Icons.library_books_rounded, Colors.purple.shade600),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _statItem('Ayat Lulus', '${santri.totalZiyadahAyahs + santri.totalMurojaahAyahs}', Icons.check_circle_outline_rounded, Colors.green),
                                  const SizedBox(width: 12),
                                  _statItem('Ayat Gagal', '${santri.totalFailedAyahs}', Icons.cancel_outlined, Colors.red),
                                ],
                              ),
                              const SizedBox(height: 20),

                              if (provider.isModuleActive('graduation') &&
                                  provider.graduationEvents.any((e) => e.isPublished)) ...[
                                _sectionHeader('Ujian Tasmi\' / Wisuda'),
                                if (santri.tasmiHistory.isEmpty)
                                  _emptyHistory('Belum ada riwayat ujian Tasmi\'')
                                else
                                  ...santri.tasmiHistory.reversed.map(
                                    (t) => _TasmiHistoryTile(record: t),
                                  ),
                                const SizedBox(height: 24),
                              ],

                              _sectionHeader('Riwayat Setoran'),
                              if (santri.setoranHistory.isEmpty)
                                _emptyHistory('Belum ada riwayat setoran')
                              else
                                ...santri.setoranHistory.reversed.map(
                                  (r) => _SetoranHistoryTile(record: r, santri: santri),
                                ),
                              const SizedBox(height: 80),
                            ],
                          ),

                          // TAB 2: PROFIL & KARTU QR
                          ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _MiniDigitalCard(santri: santri),
                              const SizedBox(height: 20),
                              _sectionHeader('Informasi Personal'),
                              _infoCard([
                                _infoRow(Icons.meeting_room_rounded, 'Kelas', santri.kelas ?? '-'),
                                _infoRow(Icons.badge_outlined, 'NIS', santri.nis ?? '-'),
                                _infoRow(Icons.cake_rounded, 'Tanggal Lahir', santri.tanggalLahir ?? '-'),
                                _infoRow(Icons.male_rounded, 'Jenis Kelamin', santri.jenisKelamin == 'P' ? 'Perempuan' : 'Laki-laki'),
                                _infoRow(Icons.history_edu_rounded, 'Hafalan Awal', santri.initialMemorizedJuz.isEmpty ? 'Mulai dari Nol' : 'Sudah hafal Juz: ${santri.initialMemorizedJuz.join(', ')}'),
                                _infoRow(Icons.email_outlined, 'Email', santri.email ?? '-'),
                                _infoRow(Icons.family_restroom_outlined, 'Orang Tua', santri.namaOrangTua ?? '-'),
                                _infoRow(Icons.phone_outlined, 'No. HP Wali', santri.nomorHpWali ?? '-'),
                                _infoRow(Icons.flag_outlined, 'Target Hafalan', santri.targetHafalan ?? '-'),
                                _infoRow(Icons.info_outline, 'Status Akun', santri.isAktif ? 'Aktif' : 'Non-aktif',
                                    valueColor: santri.isAktif ? AppTheme.primaryGreen : Colors.grey),
                              ]),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildProgressCard(Santri santri) {
    final double percentage = (santri.estimatedJuz / 30.0).clamp(0.0, 1.0);
    final String lastSetoranStr = santri.lastSetoranAt != null 
        ? _formatTimeAgo(santri.lastSetoranAt!) 
        : 'Belum pernah';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROGRES 30 JUZ',
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        santri.juzCoveredText,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 28),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniProgressInfo('Setoran Terakhir', lastSetoranStr),
              _miniProgressInfo('Status', santri.isAktif ? 'Aktif Belajar' : 'Cuti/Non-aktif'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniProgressInfo(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Hari ini';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${(diff.inDays / 7).floor()} minggu lalu';
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: valueColor ?? Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyHistory(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(msg, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      ),
    );
  }
}

class _TasmiHistoryTile extends StatelessWidget {
  const _TasmiHistoryTile({required this.record});
  final TasmiRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: record.isPass ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            record.isPass ? Icons.verified_rounded : Icons.cancel_rounded,
            color: record.isPass ? Colors.blue : Colors.red,
            size: 20,
          ),
        ),
        title: Text('Ujian Juz ${record.juzNumbers.join(", ")}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Tahun ${record.year} • Skor: ${record.finalScore.toStringAsFixed(0)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: record.isPass ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            record.isPass ? 'LULUS' : 'GAGAL',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.subtitle, this.photoPath, this.extra});
  final String name;
  final String subtitle;
  final String? photoPath;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SQUIRCLE AVATAR (Now with subtle color to pop on white)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              image: photoPath != null
                  ? DecorationImage(image: NetworkImage(photoPath!), fit: BoxFit.cover)
                  : null,
            ),
            child: photoPath == null
                ? Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, 
              fontSize: 18, 
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (extra != null) ...[
            const SizedBox(height: 12),
            extra!,
          ],
        ],
      ),
    );
  }
}

class _SetoranHistoryTile extends StatelessWidget {
  const _SetoranHistoryTile({required this.record, required this.santri});
  final SetoranRecord record;
  final Santri santri;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SetoranDetailScreen(record: record, santri: santri)),
        ),
        title: Text('${record.surahEnglishName} (${record.surahName})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ayat ${record.ayahStart}-${record.ayahEnd} • ${record.type.label}', style: const TextStyle(fontSize: 11)),
            Row(
              children: [
                Text('Lulus: ${record.passedAyahs.length}', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('Gagal: ${record.failedAyahs.length}', style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(record.finalScore.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen)),
            StarRatingWidget(rating: record.starCount, size: 12),
          ],
        ),
      ),
    );
  }
}

class _MiniDigitalCard extends StatelessWidget {
  final Santri santri;
  const _MiniDigitalCard({required this.santri});

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KARTU SANTRI DIGITAL',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<String>(
                future: context.read<AppProvider>().getLoginQrData(santri.id),
                builder: (context, snapshot) {
                  return QrImageView(
                    data: snapshot.data ?? (santri.nis ?? santri.id),
                    version: QrVersions.auto,
                    size: 180.0,
                    backgroundColor: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      child: santri.photoPath != null
                          ? Image.network(santri.photoPath!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                santri.name[0],
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          santri.name,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'NIS/ID: ${santri.nis ?? santri.id}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _showQrDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KARTU SANTRI DIGITAL',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGreen, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                      child: santri.photoPath != null
                          ? Image.network(santri.photoPath!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                santri.name[0],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGreen),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          santri.name,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIS/ID: ${santri.nis ?? santri.id}',
                          style: TextStyle(fontFamily: 'monospace', color: Colors.grey.shade600, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  QrImageView(
                    data: santri.nis ?? santri.id,
                    version: QrVersions.auto,
                    size: 60.0,
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Ketuk kartu untuk memperbesar QR Code',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
