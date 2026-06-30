import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

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
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
            ? const Center(child: Text('Data tidak ditemukan'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EducationalDetailScreen(
                            type: widget.type,
                            id: item['id'],
                            title: item['title'],
                          ),
                        ),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIcon(item['icon']), color: AppTheme.primaryGreen, size: 20),
                      ),
                      title: Text(
                        item['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item['description'],
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
  const EducationalDetailScreen({super.key, required this.type, required this.id, required this.title});
  final String type;
  final int id;
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
      final paddedId = widget.id.toString().padLeft(3, '0');
      final String response = await rootBundle.loadString('assets/data/${widget.type}/bab_$paddedId.json');
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
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
            ? const Center(child: Text('Gagal memuat materi'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_data['introduction'] != null) ...[
                      Text(
                        _data['introduction'],
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                    ],
                    ...(_data['sections'] as List).map((section) => _buildSection(section)),
                  ],
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 8),
        if (section['definition'] != null)
          Text(section['definition'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
        if (section['letters'] != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                const Text('Huruf: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Expanded(child: Text(section['letters'], style: GoogleFonts.amiri(fontSize: 20, color: AppTheme.darkGreen), textDirection: TextDirection.rtl)),
              ],
            ),
          ),
        ],
        if (section['example'] != null) ...[
          const SizedBox(height: 12),
          const Text('Contoh:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          ...(section['example'] as List).map((ex) => _buildExample(ex)),
        ],
        if (section['sub_sections'] != null)
          ...(section['sub_sections'] as List).map((sub) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: _buildSection(sub),
          )),
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
      ],
    );
  }

  Widget _buildExample(dynamic ex) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex['latin'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (ex['note'] != null) Text(ex['note'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(ex['arabic'], style: GoogleFonts.amiri(fontSize: 22, color: Colors.black87), textDirection: TextDirection.rtl),
        ],
      ),
    );
  }
}
