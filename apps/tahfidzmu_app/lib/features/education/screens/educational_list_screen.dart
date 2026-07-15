import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/education/screens/tahsin_list_screen.dart';

class EducationalListScreen extends StatefulWidget {
  const EducationalListScreen({super.key, required this.type, this.hideAppBar = false});
  final String type; // 'tajwid' or 'tahsin'
  final bool hideAppBar;

  @override
  State<EducationalListScreen> createState() => _EducationalListScreenState();
}

class _EducationalListScreenState extends State<EducationalListScreen> {
  List<dynamic> _items = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = "";
  
  // WIDE MODE STATE
  dynamic _selectedDetailData;
  String? _selectedDetailTitle;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/${widget.type}/list.json');
      final data = await json.decode(response);
      setState(() {
        _items = data;
        _filteredItems = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterList(String q) {
    setState(() {
      _searchQuery = q.toLowerCase();
      _filteredItems = _items.where((item) {
        final title = (item['title'] ?? "").toString().toLowerCase();
        final desc = (item['description'] ?? "").toString().toLowerCase();
        return title.contains(_searchQuery) || desc.contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.type == 'tajwid' ? 'Ilmu Tajwid' : (widget.type == 'fiqih' ? 'Fiqih' : 'Ilmu Tahsin');
    final bool isWide = MediaQuery.of(context).size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Widget sidebarHeader = Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextField(
        onChanged: _filterList,
        decoration: InputDecoration(
          hintText: 'Cari materi...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          isDense: true,
          filled: true,
          fillColor: isWide ? (isDark ? AppTheme.darkSurface : Colors.white) : (isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );

    Widget listWidget = Column(
      children: [
        sidebarHeader,
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _filteredItems.length,
            separatorBuilder: (ctx, i) => Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
            itemBuilder: (ctx, i) {
              final item = _filteredItems[i];
              return _TajwidAccordion(
                item: item,
                type: widget.type,
                isWide: isWide,
                isSelected: _selectedDetailTitle == item['title'],
                onDetailLoaded: (title, data) {
                  if (isWide) {
                    setState(() {
                      _selectedDetailTitle = title;
                      _selectedDetailData = data;
                    });
                  }
                },
              );
            },
          ),
        ),
      ],
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Row(
          children: [
            SizedBox(
              width: 320,
              child: Container(
                decoration: BoxDecoration(border: Border(right: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200))),
                child: listWidget,
              ),
            ),
            Expanded(
              child: _selectedDetailData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 80, color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                          const SizedBox(height: 16),
                          Text('Pilih bab Tajwid untuk membaca materi', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : EducationalDetailScreen(
                      key: ValueKey('tajwid_$_selectedDetailTitle'),
                      type: widget.type,
                      fileName: '', // Data already loaded
                      title: _selectedDetailTitle!,
                      hideAppBar: true,
                      wideModeData: _selectedDetailData,
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: listWidget,
    );
  }
}

class _TajwidAccordion extends StatefulWidget {
  const _TajwidAccordion({required this.item, required this.type, required this.isWide, required this.isSelected, required this.onDetailLoaded});
  final dynamic item;
  final String type;
  final bool isWide;
  final bool isSelected;
  final Function(String, dynamic) onDetailLoaded;

  @override
  State<_TajwidAccordion> createState() => _TajwidAccordionState();
}

class _TajwidAccordionState extends State<_TajwidAccordion> {
  bool _expanded = false;
  dynamic _detailData;
  bool _loading = false;

  Future<void> _loadDetail() async {
    if (_detailData != null) {
      widget.onDetailLoaded(widget.item['title'], _detailData);
      return;
    }
    setState(() => _loading = true);
    try {
      final fileName = widget.item['fileName'] ?? 'bab_${widget.item['id'].toString().padLeft(3, '0')}.json';
      final String response = await rootBundle.loadString('assets/data/${widget.type}/$fileName');
      final data = await json.decode(response);
      if (mounted) {
        setState(() {
          _detailData = data;
          _loading = false;
        });
        widget.onDetailLoaded(widget.item['title'], data);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        ListTile(
          selected: widget.isSelected && widget.isWide,
          selectedTileColor: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
          onTap: () {
            if (widget.isWide) {
              setState(() => _expanded = !_expanded);
              _loadDetail();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EducationalDetailScreen(
                    type: widget.type,
                    fileName: widget.item['fileName'] ?? 'bab_${widget.item['id'].toString().padLeft(3, '0')}.json',
                    title: widget.item['title'],
                  ),
                ),
              );
            }
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.1), 
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(widget.item['icon']), 
              color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen, 
              size: 18,
            ),
          ),
          title: Text(
            widget.item['title'],
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, 
              fontSize: 13, 
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          trailing: Icon(
            widget.isWide
                ? (_expanded ? Icons.expand_less : Icons.expand_more)
                : Icons.chevron_right_rounded,
            color: isDark ? Colors.white30 : Colors.grey.shade400,
            size: widget.isWide ? 16 : 18,
          ),
        ),
        if (_expanded && _loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator(minHeight: 1)),
      ],
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'auto_stories': return Icons.auto_stories_rounded;
      case 'menu_book': return Icons.menu_book_rounded;
      case 'import_contacts': return Icons.import_contacts_rounded;
      default: return Icons.book_rounded;
    }
  }
}

class EducationalDetailScreen extends StatefulWidget {
  const EducationalDetailScreen({super.key, required this.type, required this.fileName, required this.title, this.hideAppBar = false, this.wideModeData});
  final String type;
  final String fileName;
  final String title;
  final bool hideAppBar;
  final dynamic wideModeData;

  @override
  State<EducationalDetailScreen> createState() => _EducationalDetailScreenState();
}

class _EducationalDetailScreenState extends State<EducationalDetailScreen> {
  dynamic _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.wideModeData != null) {
      _data = widget.wideModeData;
      _isLoading = false;
    } else {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    try {
      final String response = await rootBundle.loadString('assets/data/${widget.type}/${widget.fileName}');
      final data = await json.decode(response);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: Text(widget.title),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
            ? const Center(child: Text('Gagal memuat materi'))
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.hideAppBar) ...[
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, 
                            fontSize: 24, 
                            color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),
                        const SizedBox(height: 20),
                      ],
                      if (_data['introduction'] != null) ...[
                        Text(
                          'PENDAHULUAN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _data['introduction'],
                          style: GoogleFonts.poppins(
                            fontSize: 14, 
                            color: isDark ? Colors.white70 : const Color(0xFF1E293B), 
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      ...(_data['sections'] as List).map((section) => _buildSection(section)),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSection(dynamic section) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section['name'],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
          ),
        ),
        const SizedBox(height: 12),
        if (section['definition'] != null) _buildSmartContent(section['definition']),
        if (section['letters'] != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  section['letters'],
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 32,
                    color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Huruf',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (section['example'] != null) ...[
          const SizedBox(height: 16),
          Text(
            'Contoh:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          ...(section['example'] as List).map((ex) => _buildExample(context, ex)),
        ],
        if (section['sub_sections'] != null) ...[
          const SizedBox(height: 12),
          ...(section['sub_sections'] as List).map((sub) => _buildSubSection(sub)),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
      ],
    );
  }

  Widget _buildSubSection(dynamic sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sub['name'],
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          if (sub['definition'] != null) _buildSmartContent(sub['definition']),
          if (sub['letters'] != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sub['letters'],
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 32,
                      color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Huruf',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (sub['example'] != null) ...[
            const SizedBox(height: 16),
            Text(
              'Contoh:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
            ...(sub['example'] as List).map((ex) => _buildExample(context, ex)),
          ],
        ],
      ),
    );
  }

  Widget _buildSmartContent(String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lines = content.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 8);

        // Detect Link Placeholder [LINK:...]
        if (trimmed.startsWith('[LINK:')) {
          return _buildLinkButton(trimmed);
        }

        // Detect Arabic lines (Must contain at least one Arabic letter and NO Latin alphabetic characters)
        final hasArabicLetters = RegExp(r'[\u0621-\u064A\u0671-\u06D3]').hasMatch(line);
        final hasLatinLetters = RegExp(r'[a-zA-Z]').hasMatch(line);

        if (hasArabicLetters && !hasLatinLetters) {
          return _buildArabicCard(line);
        }

        // Detect Numbering (e.g. 1. Niat)
        final numMatch = RegExp(r'^(\d+)\.\s(.*)').firstMatch(trimmed);
        if (numMatch != null) {
          return _buildListItem(numMatch.group(1)!, numMatch.group(2)!, isNumeric: true);
        }

        // Detect Bullet (e.g. - Membasuh)
        final bulletMatch = RegExp(r'^([\-\*])\s(.*)').firstMatch(trimmed);
        if (bulletMatch != null) {
          return _buildListItem('•', bulletMatch.group(2)!, isNumeric: false);
        }

        // Regular line (Paragraph part)
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            line,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              height: 1.6,
              fontWeight: line.contains(':') ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListItem(String leading, String text, {required bool isNumeric}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNumeric)
            Container(
              margin: const EdgeInsets.only(top: 2, right: 10),
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                leading,
                style: TextStyle(
                  color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: 7, right: 12, left: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.accentGreen : AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicCard(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16), // Slimmer padding for HP
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, width: 1.2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: 22, // Optimized size for HP
          color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
          height: 1.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLinkButton(String tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String label = "Buka Panduan";
    VoidCallback? action;

    if (tag.contains("TAHSIN_FATIHAH")) {
      label = "Belajar Tahsin Surat Al-Fatihah";
      action = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TahsinListScreen()),
        );
      };
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: OutlinedButton.icon(
        onPressed: action,
        icon: const Icon(Icons.record_voice_over_rounded, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
          side: BorderSide(color: isDark ? AppTheme.accentGreen : AppTheme.primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildExample(BuildContext context, dynamic ex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : const Color(0xFFFAF9F6), 
        border: Border(
          left: BorderSide(
            color: isDark ? AppTheme.accentGreen : AppTheme.primaryGreen, 
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex['latin'], 
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, 
                    fontSize: 14, 
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (ex['note'] != null) 
                  Text(
                    ex['note'], 
                    style: TextStyle(
                      fontSize: 11, 
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            ex['arabic'], 
            style: GoogleFonts.amiri(
              fontSize: 26, 
              color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen, 
              fontWeight: FontWeight.bold,
            ), 
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
