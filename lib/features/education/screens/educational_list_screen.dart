import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EducationalListScreen extends StatefulWidget {
  const EducationalListScreen({super.key, required this.type, this.hideAppBar = false});
  final String type; // 'tajwid' or 'tahsin'
  final bool hideAppBar;

  @override
  State<EducationalListScreen> createState() => _EducationalListScreenState();
}

class _EducationalListScreenState extends State<EducationalListScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.type == 'tajwid' ? 'Ilmu Tajwid' : 'Ilmu Tahsin';
    final bool isWide = MediaQuery.of(context).size.width > 900;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Widget sidebar = ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: _items.length,
      separatorBuilder: (ctx, i) => const Divider(color: Color(0xFFE5D5B8), height: 1),
      itemBuilder: (ctx, i) {
        final item = _items[i];
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
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFFDF9F0),
        appBar: AppBar(
          title: Text(title),
          backgroundColor: const Color(0xFF2E5A27),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Row(
          children: [
            SizedBox(
              width: 320,
              child: Container(
                decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE5D5B8)))),
                child: sidebar,
              ),
            ),
            Expanded(
              child: _selectedDetailData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 80, color: const Color(0xFF2E5A27).withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          Text('Pilih bab Tajwid untuk membaca materi', style: TextStyle(color: Colors.grey.shade600)),
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
      backgroundColor: const Color(0xFFFDF9F0),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2E5A27),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: sidebar,
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
    return Column(
      children: [
        ListTile(
          selected: widget.isSelected && widget.isWide,
          selectedTileColor: const Color(0xFFF4EAD4),
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
            decoration: BoxDecoration(color: const Color(0xFF2E5A27).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(_getIcon(widget.item['icon']), color: const Color(0xFF2E5A27), size: 18),
          ),
          title: Text(
            widget.item['title'],
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF4E342E)),
          ),
          trailing: widget.isWide ? Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16) : const Icon(Icons.chevron_right_rounded, size: 18),
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
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF2E5A27),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFDF9F0),
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
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24, color: const Color(0xFF2E5A27)),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFE5D5B8)),
                        const SizedBox(height: 20),
                      ],
                      if (_data['introduction'] != null) ...[
                        Text(
                          _data['introduction'],
                          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF4E342E), height: 1.7),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2E5A27))),
        const SizedBox(height: 10),
        if (section['definition'] != null) Text(section['definition'], style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF5D4037), height: 1.6)),
        if (section['letters'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF4EAD4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5D5B8))),
            child: Row(children: [const Text('Huruf: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4E342E))), Expanded(child: Text(section['letters'], style: GoogleFonts.amiri(fontSize: 24, color: const Color(0xFF1B5E20), fontWeight: FontWeight.bold), textDirection: TextDirection.rtl))]),
          ),
        ],
        if (section['example'] != null) ...[
          const SizedBox(height: 16),
          const Text('Contoh:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF8D6E63))),
          ...(section['example'] as List).map((ex) => _buildExample(ex)),
        ],
        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFE5D5B8))),
      ],
    );
  }

  Widget _buildExample(dynamic ex) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFFFAF6EE), border: Border(left: BorderSide(color: Color(0xFFE5D5B8), width: 4))),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(ex['latin'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF4E342E))), if (ex['note'] != null) Text(ex['note'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500))])),
          Text(ex['arabic'], style: GoogleFonts.amiri(fontSize: 26, color: const Color(0xFF2E5A27), fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
        ],
      ),
    );
  }
}
