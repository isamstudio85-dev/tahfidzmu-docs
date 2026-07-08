import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EducationalListScreen extends StatefulWidget {
  const EducationalListScreen({super.key, required this.type});
  final String type; // 'tajwid' or 'tahsin'

  @override
  State<EducationalListScreen> createState() => _EducationalListScreenState();
}

class _EducationalListScreenState extends State<EducationalListScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;

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
    
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F0), // Classic warm parchment (Kitab Kuning background)
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2E5A27), // Deep olive green for classic book header
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
            ? const Center(child: Text('Data tidak ditemukan'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _items.length,
                separatorBuilder: (ctx, i) => const Divider(
                  color: Color(0xFFE5D5B8),
                  height: 1,
                  thickness: 1.2,
                ),
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  return Container(
                    color: const Color(0xFFFDF9F0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EducationalDetailScreen(
                            type: widget.type,
                            fileName: item['fileName'] ?? 'bab_${item['id'].toString().padLeft(3, '0')}.json',
                            title: item['title'],
                          ),
                        ),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E5A27).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIcon(item['icon']), color: const Color(0xFF2E5A27), size: 20),
                      ),
                      title: Text(
                        item['title'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF4E342E), // Soft Espresso
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item['description'],
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2E5A27)),
                    ),
                  );
                },
              ),
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'auto_stories': return Icons.auto_stories_rounded;
      case 'menu_book': return Icons.menu_book_rounded;
      case 'import_contacts': return Icons.import_contacts_rounded;
      case 'straighten': return Icons.straighten_rounded;
      case 'vibration': return Icons.vibration_rounded;
      case 'record_voice_over': return Icons.record_voice_over_rounded;
      case 'settings_voice': return Icons.settings_voice_rounded;
      case 'warning_amber': return Icons.warning_amber_rounded;
      default: return Icons.book_rounded;
    }
  }
}

class EducationalDetailScreen extends StatefulWidget {
  const EducationalDetailScreen({super.key, required this.type, required this.fileName, required this.title});
  final String type;
  final String fileName;
  final String title;

  @override
  State<EducationalDetailScreen> createState() => _EducationalDetailScreenState();
}

class _EducationalDetailScreenState extends State<EducationalDetailScreen> {
  dynamic _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
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
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF2E5A27), // Deep olive green for classic book header
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFDF9F0), // Classic warm parchment (Kitab Kuning background)
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
            ? const Center(child: Text('Gagal memuat materi'))
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_data['introduction'] != null) ...[
                        Text(
                          _data['introduction'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF4E342E), // Soft Espresso
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      ...(_data['sections'] as List).map((section) => _buildSection(section)),
                      if (_data['reference'] != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E5A27).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2E5A27).withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                color: Color(0xFF2E5A27),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _data['reference'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2E5A27),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
        Text(
          section['name'],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: const Color(0xFF2E5A27), // Deep classic green
          ),
        ),
        const SizedBox(height: 8),
        if (section['definition'] != null)
          Text(
            section['definition'],
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF5D4037),
              height: 1.5,
            ),
          ),
        if (section['letters'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EAD4), // Classic yellow highlight/letters backing
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5D5B8)),
            ),
            child: Row(
              children: [
                const Text(
                  'Huruf: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF4E342E),
                  ),
                ),
                Expanded(
                  child: Text(
                    section['letters'],
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      color: const Color(0xFF1B5E20),
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (section['example'] != null) ...[
          const SizedBox(height: 12),
          const Text(
            'Contoh:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF8D6E63),
            ),
          ),
          ...(section['example'] as List).map((ex) => _buildExample(ex)),
        ],
        if (section['sub_sections'] != null)
          ...(section['sub_sections'] as List).map((sub) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: _buildSection(sub),
          )),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: Color(0xFFE5D5B8)),
        ),
      ],
    );
  }

  Widget _buildExample(dynamic ex) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF6EE), // soft warm tint
        border: Border(
          left: BorderSide(color: Color(0xFFE5D5B8), width: 3.5), // classic left line indicator
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
                    fontSize: 13,
                    color: const Color(0xFF4E342E),
                  ),
                ),
                if (ex['note'] != null)
                  Text(
                    ex['note'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            ex['arabic'],
            style: GoogleFonts.amiri(
              fontSize: 24,
              color: const Color(0xFF2E5A27),
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
