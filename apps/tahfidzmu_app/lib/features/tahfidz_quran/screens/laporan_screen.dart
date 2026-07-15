import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/quran_memorization_screen.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const QuranMemorizationScreen();
  }
}

class LaporanScreenBody extends StatefulWidget {
  const LaporanScreenBody({super.key, required this.setorans, required this.provider});
  final List<SetoranRecord> setorans;
  final AppProvider provider;

  @override
  State<LaporanScreenBody> createState() => _LaporanScreenBodyState();
}

class _LaporanScreenBodyState extends State<LaporanScreenBody> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String? _selectedHalaqahId;
  
  // Cache for attendance stats: Map<SantriId, Map<Status, Count>>
  Map<String, Map<String, int>> _attendanceCache = {};

  @override
  void initState() {
    super.initState();
    _calculateAttendanceCache();
  }

  @override
  void didUpdateWidget(LaporanScreenBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.presensiList != widget.provider.presensiList) {
      _calculateAttendanceCache();
    }
  }

  void _calculateAttendanceCache() {
    final Map<String, Map<String, int>> newCache = {};
    final monthPresensi = widget.provider.presensiList.where((p) => 
      p.tanggal.month == _selectedDate.month && 
      p.tanggal.year == _selectedDate.year
    ).toList();

    for (var s in widget.provider.santriList) {
      int h = 0, sakit = 0, izin = 0, alfa = 0;
      for (var p in monthPresensi) {
        final status = p.daftarHadir[s.id];
        if (status == 'setoran' || status == 'ditunda') {
          h++;
        } else if (status == 'sakit') {
          sakit++;
        } else if (status == 'izin') {
          izin++;
        } else if (status == 'alfa') {
          alfa++;
        }
      }
      newCache[s.id] = {'H': h, 'S': sakit, 'I': izin, 'A': alfa};
    }

    setState(() {
      _attendanceCache = newCache;
    });
  }

  List<SetoranRecord> get _filteredSetorans {
    return widget.setorans.where((s) => 
      s.date.month == _selectedDate.month && 
      s.date.year == _selectedDate.year
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filtered = _filteredSetorans;
    final ziyadah = filtered.where((s) => s.type == SetoranType.ziyadah).length;
    final murojaah = filtered.length - ziyadah;
    final totalScores = filtered.map((s) => s.finalScore).toList();
    final avg = totalScores.isEmpty ? 0.0 : totalScores.reduce((a, b) => a + b) / (filtered.isEmpty ? 1 : filtered.length);
    
    final errors = filtered.expand((s) => s.errorMarks).toList();
    final tajwidCount = errors.where((e) => e.errorType == ErrorType.tajwid).length;
    final makhrojCount = errors.length - tajwidCount;

    return LayoutBuilder(
      builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 700;
          
          return ListView(
            padding: EdgeInsets.fromLTRB(isTablet ? 40 : 20, 16, isTablet ? 40 : 20, 100),
            children: [
              _buildMonthYearPicker(),
              const SizedBox(height: 20),

              // 1. Hero Performance Header
              _buildHeroHeader(avg, filtered.length),
              const SizedBox(height: 20),

              // 2. Metric Cards
              _buildMetricGrid(isTablet, ziyadah, murojaah, filtered),
              const SizedBox(height: 28),

              // 3. Middle Section
              if (isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('PENCAPAIAN TARGET (TAHUN ${_selectedDate.year})'),
                          const SizedBox(height: 10),
                          _buildTargetAchievementCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('ANALISIS KESALAHAN'),
                          const SizedBox(height: 10),
                          _buildMinimalistErrorCard(tajwidCount, makhrojCount),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('PENCAPAIAN TARGET (TAHUN ${_selectedDate.year})'),
                    const SizedBox(height: 10),
                    _buildTargetAchievementCard(),
                    const SizedBox(height: 28),
                    _buildSectionHeader('ANALISIS KESALAHAN'),
                    const SizedBox(height: 10),
                    _buildMinimalistErrorCard(tajwidCount, makhrojCount),
                  ],
                ),
              const SizedBox(height: 28),

              // 4. Attendance Summary Section
              _buildSectionHeader('REKAP KEHADIRAN ${_getMonthName(_selectedDate).toUpperCase()} ${_selectedDate.year}'),
              const SizedBox(height: 10),
              _buildAttendanceSummaryCard(),
              const SizedBox(height: 12),
              if (!widget.provider.isOrangTua) ...[
                _buildDetailedSantriAttendance(),
                const SizedBox(height: 28),
              ],

              // 5. Weekly Activity Chart
              _buildSectionHeader('AKTIVITAS MINGGUAN (REAL-TIME)'),
              const SizedBox(height: 10),
              _WeeklyActivityCard(setorans: widget.setorans, sectionCard: _sectionCard),
              
              if (!widget.provider.isOrangTua) ...[
                const SizedBox(height: 32),
                _buildExportButton(),
              ],
            ],
          );
        },
    );
  }

  Widget _buildMonthYearPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
              });
              _calculateAttendanceCache();
            },
          ),
          Column(
            children: [
              Text(
                _getMonthName(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
              ),
              Text(
                '${_selectedDate.year}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
              });
              _calculateAttendanceCache();
            },
          ),
        ],
      ),
    );
  }

  String _getMonthName(DateTime date) {
    return DateFormat('MMMM', 'id_ID').format(date);
  }

  Widget _buildDetailedSantriAttendance() {
    var santriList = widget.provider.santriList;
    
    // Apply filters
    if (_selectedHalaqahId != null) {
      santriList = santriList.where((s) => s.halaqahId == _selectedHalaqahId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      santriList = santriList.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (santriList.isEmpty) return const SizedBox.shrink();

    return _sectionCard(
      backgroundColor: Colors.white,
      borderColor: Colors.grey.shade200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rekap Per Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              Text('${santriList.length} Santri', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          
          // Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Cari nama...',
                    prefixIcon: const Icon(Icons.search, size: 16),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<String?>(
                  value: _selectedHalaqahId,
                  underline: const SizedBox(),
                  hint: const Text('Semua', style: TextStyle(fontSize: 11)),
                  icon: const Icon(Icons.filter_list_rounded, size: 16),
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Halaqah')),
                    ...widget.provider.halaqahList.map((h) => DropdownMenuItem(value: h.id, child: Text(h.nama))),
                  ],
                  onChanged: (v) => setState(() => _selectedHalaqahId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: santriList.length,
            separatorBuilder: (_, __) => const Divider(height: 16, thickness: 0.5),
            itemBuilder: (ctx, i) {
              final s = santriList[i];
              final stats = _attendanceCache[s.id] ?? {'H': 0, 'S': 0, 'I': 0, 'A': 0};
              
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  _miniBadge('${stats['H']} H', Colors.green),
                  const SizedBox(width: 4),
                  _miniBadge('${stats['S']} S', Colors.orange),
                  const SizedBox(width: 4),
                  _miniBadge('${stats['I']} I', Colors.blue),
                  const SizedBox(width: 4),
                  _miniBadge('${stats['A']} A', Colors.red),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      width: 32,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAttendanceSummaryCard() {
    final thisMonthPresensi = widget.provider.presensiList.where((p) => 
      p.tanggal.month == _selectedDate.month && 
      p.tanggal.year == _selectedDate.year
    ).toList();
    
    int totalHadir = 0;
    int totalSakit = 0;
    int totalIzin = 0;
    int totalAlfa = 0;

    for (var p in thisMonthPresensi) {
      for (var status in p.daftarHadir.values) {
        if (status == 'setoran' || status == 'ditunda') {
          totalHadir++;
        } else if (status == 'sakit') {
          totalSakit++;
        } else if (status == 'izin') {
          totalIzin++;
        } else if (status == 'alfa') {
          totalAlfa++;
        }
      }
    }

    final totalEntries = totalHadir + totalSakit + totalIzin + totalAlfa;
    final double attendanceRate = totalEntries == 0 ? 0 : (totalHadir / totalEntries) * 100;

    return _sectionCard(
      backgroundColor: const Color(0xFFF1F8E9),
      borderColor: const Color(0xFFC8E6C9),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rasio Kehadiran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  Text('${attendanceRate.toStringAsFixed(1)}%', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2))),
                child: Text('${thisMonthPresensi.length} Hari Aktif', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _attItem('Hadir', totalHadir, Colors.green),
              _attItem('Sakit', totalSakit, Colors.orange),
              _attItem('Izin', totalIzin, Colors.blue),
              _attItem('Alfa', totalAlfa, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(bool isTablet, int ziyadah, int murojaah, List<SetoranRecord> filtered) {
    final passedCount = filtered.fold(0, (sum, r) => sum + r.passedAyahs.length);
    final failedCount = filtered.fold(0, (sum, r) => sum + r.failedAyahs.length);

    if (isTablet) {
      return Row(
        children: [
          Expanded(child: _metricCard(label: 'Ziyadah', value: '$ziyadah', icon: Icons.add_chart_rounded, iconColor: AppTheme.primaryGreen, backgroundColor: const Color(0xFFE8F5E9), borderColor: const Color(0xFFC8E6C9))),
          const SizedBox(width: 12),
          Expanded(child: _metricCard(label: "Muroja'ah", value: '$murojaah', icon: Icons.history_rounded, iconColor: Colors.purple.shade700, backgroundColor: const Color(0xFFF3E5F5), borderColor: const Color(0xFFE1BEE7))),
          const SizedBox(width: 12),
          Expanded(child: _metricCard(label: 'Ayat Lulus', value: '$passedCount', icon: Icons.check_circle_outline_rounded, iconColor: Colors.teal.shade700, backgroundColor: const Color(0xFFE0F2F1), borderColor: const Color(0xFFB2DFDB))),
          const SizedBox(width: 12),
          Expanded(child: _metricCard(label: 'Ayat Gagal', value: '$failedCount', icon: Icons.error_outline_rounded, iconColor: Colors.red.shade700, backgroundColor: const Color(0xFFFFEBEE), borderColor: const Color(0xFFFFCDD2))),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard(label: 'Ziyadah', value: '$ziyadah', icon: Icons.add_chart_rounded, iconColor: AppTheme.primaryGreen, backgroundColor: const Color(0xFFE8F5E9), borderColor: const Color(0xFFC8E6C9))),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(label: "Muroja'ah", value: '$murojaah', icon: Icons.history_rounded, iconColor: Colors.purple.shade700, backgroundColor: const Color(0xFFF3E5F5), borderColor: const Color(0xFFE1BEE7))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard(label: 'Ayat Lulus', value: '$passedCount', icon: Icons.check_circle_outline_rounded, iconColor: Colors.teal.shade700, backgroundColor: const Color(0xFFE0F2F1), borderColor: const Color(0xFFB2DFDB))),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(label: 'Ayat Gagal', value: '$failedCount', icon: Icons.error_outline_rounded, iconColor: Colors.red.shade700, backgroundColor: const Color(0xFFFFEBEE), borderColor: const Color(0xFFFFCDD2))),
          ],
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('CETAK RAPOR PDF (RESMI)', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            onPressed: _generatePdfReport,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.copy_all_rounded, size: 18),
            label: const Text('Salin Ringkasan Teks (WhatsApp)', style: TextStyle(fontSize: 12)),
            onPressed: _exportMonthlySummary,
          ),
        ),
      ],
    );
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    final monthName = _getMonthName(_selectedDate);
    final santriList = widget.provider.santriList;
    final info = widget.provider.pesantrenInfo;

    try {
      // ── PREPARE LOGOS ──────────────────────────────────────────────────────
      pw.MemoryImage? logoPesantren;
      pw.MemoryImage? logoTahfidzMu;

      try {
        final tahfidzMuBytes = await rootBundle.load('assets/images/TahfidzMU-logo.png');
        logoTahfidzMu = pw.MemoryImage(tahfidzMuBytes.buffer.asUint8List());
      } catch (e) {
        debugPrint('Error loading TahfidzMU logo: $e');
      }

      if (info.logoPath.isNotEmpty) {
        try {
          if (info.logoPath.startsWith('http')) {
            final response = await http.get(Uri.parse(info.logoPath)).timeout(const Duration(seconds: 5));
            if (response.statusCode == 200) {
              logoPesantren = pw.MemoryImage(response.bodyBytes);
            }
          }
        } catch (e) {
          debugPrint('Error loading Pesantren logo: $e');
        }
      }

      // ── BUILD PDF ──────────────────────────────────────────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // OFFICIAL HEADER (KOP SURAT)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Pesantren Logo (LEFT)
                  if (logoPesantren != null)
                    pw.Container(
                      width: 65,
                      height: 60,
                      margin: const pw.EdgeInsets.only(right: 12),
                      child: pw.Image(logoPesantren, fit: pw.BoxFit.contain),
                    ),
                  
                  // Pesantren Info (CENTER)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          info.nama.toUpperCase(),
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(info.alamat, style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(
                          'Telp: ${info.noTelp} | Email: ${info.email}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        if (info.website.isNotEmpty)
                          pw.Text('Website: ${info.website}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),

                  // TahfidzMU Logo (RIGHT)
                  if (logoTahfidzMu != null)
                    pw.Container(
                      width: 45,
                      height: 45,
                      margin: const pw.EdgeInsets.only(left: 12),
                      child: pw.Image(logoTahfidzMu, fit: pw.BoxFit.contain),
                    ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 2, color: PdfColors.black),
              pw.SizedBox(height: 1),
              pw.Divider(thickness: 0.5, color: PdfColors.black),
              pw.SizedBox(height: 20),

              // REPORT TITLE
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'LAPORAN PERKEMBANGAN TAHFIDZ AL-QURAN',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'PERIODE: $monthName ${_selectedDate.year}'.toUpperCase(),
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // SUMMARY TABLE
              pw.Text('I. RINGKASAN KOLEKTIF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                headerHeight: 25,
                cellHeight: 18,
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                },
                headers: ['Kategori Statistik', 'Nilai / Jumlah'],
                data: [
                  ['Total Sesi Setoran', _filteredSetorans.length.toString()],
                  ['Total Ziyadah (Hafalan Baru)', _filteredSetorans.where((s) => s.type == SetoranType.ziyadah).length.toString()],
                  ['Total Murojaah (Mengulang)', _filteredSetorans.where((s) => s.type == SetoranType.murojaah).length.toString()],
                  ['Rata-rata Skor Kelancaran', (widget.setorans.isEmpty ? 0.0 : widget.setorans.map((s) => s.finalScore).reduce((a,b)=>a+b)/widget.setorans.length).toStringAsFixed(1)],
                ],
              ),
              pw.SizedBox(height: 24),

              // DETAILED LIST
              pw.Text('II. REKAP KEHADIRAN & PROGRES SANTRI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FixedColumnWidth(40),
                  2: const pw.FixedColumnWidth(40),
                  3: const pw.FixedColumnWidth(40),
                  4: const pw.FixedColumnWidth(40),
                  5: const pw.FixedColumnWidth(50),
                },
                headers: ['Nama Santri', 'Hadir', 'Sakit', 'Izin', 'Alfa', 'Total Juz'],
                data: santriList.map((s) {
                  final stats = _attendanceCache[s.id] ?? {'H': 0, 'S': 0, 'I': 0, 'A': 0};
                  return [
                    s.name,
                    stats['H'].toString(),
                    stats['S'].toString(),
                    stats['I'].toString(),
                    stats['A'].toString(),
                    s.estimatedJuz.toStringAsFixed(1),
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 40),
              // FOOTER SIGNATURE
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Dicetak pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 7)),
                      pw.SizedBox(height: 12),
                      pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Admin / Musyrif Koordinator', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.SizedBox(height: 45),
                      pw.Text('__________________________', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(info.pimpinan.isNotEmpty ? info.pimpinan : '( Nama Terang )', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Tahfidz_$monthName.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _exportMonthlySummary() {
    final monthName = _getMonthName(_selectedDate);
    final filtered = _filteredSetorans;
    final ziyadah = filtered.where((s) => s.type == SetoranType.ziyadah).length;
    final murojaah = filtered.length - ziyadah;
    final totalAyahs = filtered.fold(0, (sum, r) => sum + r.passedAyahs.length);
    
    final summary = "REKAP TAHFIDZMU - $monthName ${_selectedDate.year}\n"
        "---------------------------\n"
        "Total Sesi: ${filtered.length}\n"
        "Ziyadah: $ziyadah\n"
        "Muroja'ah: $murojaah\n"
        "Total Ayat Lulus: $totalAyahs\n"
        "---------------------------\n"
        "Laporan ini digenerate secara otomatis.";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rekap Laporan'),
        content: SelectableText(summary),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summary));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rekap berhasil disalin!')));
            }, 
            child: const Text('Salin Teks')
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade700, 
                    fontSize: 9, 
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required Widget child, 
    required Color backgroundColor, 
    required Color borderColor,
    Color? shadowColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? Colors.black).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeroHeader(double avg, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rata-rata Skor',
                style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                avg.toStringAsFixed(0),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold, height: 1.1),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$total',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sesi Terpilih',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetAchievementCard() {
    final isOrangTua = widget.provider.isOrangTua && widget.provider.linkedSantriId != null;
    
    double progress = 0.0;
    int currentAyahs = 0;
    const targetAyahs = 604; // 1 Juz
    String descText = '';
    String titleText = 'Target Tahunan';

    if (isOrangTua) {
      final santri = widget.provider.getSantriById(widget.provider.linkedSantriId!);
      if (santri == null) return const SizedBox.shrink();
      currentAyahs = santri.totalZiyadahAyahs;
      progress = (currentAyahs / targetAyahs).clamp(0.0, 1.0);
      descText = '$currentAyahs dari $targetAyahs Ayat berhasil dihafal tahun ini.';
      titleText = 'Target Tahunan Santri (1 Juz)';
    } else {
      final sourceList = widget.provider.isMusyrif && widget.provider.linkedMusyrif != null 
          ? widget.provider.getSantriByMusyrif(widget.provider.linkedMusyrif!.id) 
          : widget.provider.santriList;
      
      if (sourceList.isEmpty) {
        return _sectionCard(
          backgroundColor: const Color(0xFFEBF3FC),
          borderColor: const Color(0xFFD2E3FC),
          child: const Text('Belum ada data santri untuk kalkulasi target.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        );
      }
      
      int totalAyahs = sourceList.fold(0, (sum, s) => sum + s.totalZiyadahAyahs);
      currentAyahs = totalAyahs ~/ sourceList.length;
      progress = (currentAyahs / targetAyahs).clamp(0.0, 1.0);
      descText = 'Rata-rata santri halaqah menghafal $currentAyahs dari $targetAyahs Ayat target tahun ini.';
      titleText = 'Rata-rata Target Halaqah (1 Juz)';
    }

    return _sectionCard(
      backgroundColor: const Color(0xFFEBF3FC),
      borderColor: const Color(0xFFD2E3FC),
      shadowColor: Colors.blue.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A73E8))),
              Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A73E8))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              color: const Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 12),
          Text(descText, style: const TextStyle(fontSize: 11, color: Color(0xFF185ABC))),
        ],
      ),
    );
  }

  Widget _buildMinimalistErrorCard(int tajwid, int makhroj) {
    final total = tajwid + makhroj;
    final double tajwidRatio = total == 0 ? 0.5 : tajwid / total;
    
    return _sectionCard(
      backgroundColor: const Color(0xFFFFF3E0),
      borderColor: const Color(0xFFFFE0B2),
      shadowColor: Colors.orange.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _errorLabel('Tajwid', tajwid, AppTheme.tajwidColor),
              _errorLabel('Makhroj', makhroj, AppTheme.makhrojColor),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (tajwidRatio * 100).round(),
                    child: Container(color: AppTheme.tajwidColor),
                  ),
                  Expanded(
                    flex: ((1 - tajwidRatio) * 100).round(),
                    child: Container(color: AppTheme.makhrojColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              total == 0 ? 'Tidak ada kesalahan tercatat' : 'Total $total Kesalahan Terdeteksi',
              style: const TextStyle(fontSize: 10, color: Color(0xFFE65100), fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorLabel(String name, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$name: ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
        Text(
          '$count',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _attItem(String label, int val, Color color) {
    return Column(
      children: [
        Text('$val', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.setorans, required this.sectionCard});
  final List<SetoranRecord> setorans;
  final Widget Function({required Widget child, required Color backgroundColor, required Color borderColor, Color? shadowColor}) sectionCard;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final maxSetoran = days.map((d) => setorans.where((s) => s.date.day == d.day && s.date.month == d.month).length).fold(0, (a, b) => a > b ? a : b);

    return sectionCard(
      backgroundColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFFC8E6C9),
      shadowColor: AppTheme.primaryGreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final count = setorans.where((s) => s.date.day == d.day && s.date.month == d.month).length;
          final ratio = maxSetoran == 0 ? 0.0 : count / maxSetoran;
          final isToday = d.day == now.day && d.month == now.month;

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 18,
                height: (80 * ratio).clamp(4.0, 80.0),
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.primaryGreen : AppTheme.primaryGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'][d.weekday - 1],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? AppTheme.primaryGreen : Colors.grey.shade600,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
