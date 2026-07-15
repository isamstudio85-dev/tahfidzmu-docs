import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class PondokKnowledgeScreen extends StatefulWidget {
  const PondokKnowledgeScreen({super.key});

  @override
  State<PondokKnowledgeScreen> createState() => _PondokKnowledgeScreenState();
}

class _PondokKnowledgeScreenState extends State<PondokKnowledgeScreen> {
  int? _selectedIndex;

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Informasi?'),
        content: const Text('Informasi ini akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final provider = context.read<AppProvider>();
              final currentList = List<Map<String, dynamic>>.from(provider.pondokKnowledgeList);
              currentList.removeAt(index);
              provider.updatePondokKnowledge(currentList);
              setState(() => _selectedIndex = currentList.isEmpty ? null : 0);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isAdmin = provider.isAdmin;
    final displayList = provider.pondokKnowledgeList;
    final bool isWide = MediaQuery.of(context).size.width > 900;

    if (_selectedIndex == null && displayList.isNotEmpty) {
      _selectedIndex = 0;
    }

    Widget listWidget = displayList.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Belum ada informasi pondok.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: displayList.length,
            separatorBuilder: (ctx, i) => const Divider(color: Color(0xFFE5D5B8), height: 1),
            itemBuilder: (ctx, i) {
              final item = displayList[i];
              final isSelected = _selectedIndex == i;

              return ListTile(
                onTap: () => setState(() => _selectedIndex = isWide ? i : (_selectedIndex == i ? -1 : i)),
                selected: isSelected && isWide,
                selectedTileColor: const Color(0xFFF4EAD4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF2E5A27).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF2E5A27), size: 18),
                ),
                title: Text(item['title'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF4E342E))),
                trailing: isWide ? null : Icon(_selectedIndex == i ? Icons.expand_less : Icons.expand_more),
              );
            },
          );

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F0),
      appBar: AppBar(
        title: const Text('Pengetahuan Pondok'),
        backgroundColor: const Color(0xFF2E5A27),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isWide
          ? Row(
              children: [
                SizedBox(width: 320, child: Container(decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE5D5B8)))), child: listWidget)),
                Expanded(
                  child: _selectedIndex == null || _selectedIndex! < 0 || _selectedIndex! >= displayList.length
                      ? const Center(child: Text('Pilih informasi untuk melihat detail'))
                      : _PondokDetailView(
                          item: displayList[_selectedIndex!],
                          isAdmin: isAdmin,
                          onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PondokKnowledgeEditPage(item: displayList[_selectedIndex!], index: _selectedIndex))),
                          onDelete: () => _deleteItem(_selectedIndex!),
                        ),
                ),
              ],
            )
          : displayList.isEmpty
              ? listWidget
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayList.length,
                  itemBuilder: (ctx, i) {
                    final isExpanded = _selectedIndex == i;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isExpanded ? const Color(0xFFE5D5B8) : Colors.grey.shade100)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () => setState(() => _selectedIndex = isExpanded ? -1 : i),
                            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF2E5A27).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.school_rounded, color: Color(0xFF2E5A27), size: 18)),
                            title: Text(displayList[i]['title'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF4E342E))),
                            trailing: Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                          ),
                          if (isExpanded)
                            _PondokDetailView(
                              item: displayList[i],
                              isAdmin: isAdmin,
                              onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PondokKnowledgeEditPage(item: displayList[i], index: i))),
                              onDelete: () => _deleteItem(i),
                              compact: true,
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PondokKnowledgeEditPage())),
              backgroundColor: const Color(0xFF2E5A27),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Materi'),
            )
          : null,
    );
  }
}

class _PondokDetailView extends StatelessWidget {
  const _PondokDetailView({required this.item, required this.isAdmin, required this.onEdit, required this.onDelete, this.compact = false});
  final Map<String, dynamic> item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final type = item['type'] ?? 'paragraph';
    final isListType = type == 'bullet' || type == 'number';
    final contentText = item['content'] ?? '';
    final List<String> listItems = isListType ? contentText.toString().split('\n').where((s) => s.trim().isNotEmpty).toList() : [];
    final hasImage = item['imagePath'] != null && item['imagePath'].toString().isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            Text(item['title'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24, color: const Color(0xFF2E5A27))),
            const SizedBox(height: 8),
            if (item['description'] != null) Text(item['description'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE5D5B8)),
            const SizedBox(height: 20),
          ],
          if (hasImage)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item['imagePath'].toString().startsWith('http') ? Image.network(item['imagePath'], fit: BoxFit.cover, width: double.infinity) : Image.file(File(item['imagePath']), fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
          if (isListType)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(listItems.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (type == 'bullet') Container(margin: const EdgeInsets.only(top: 8, right: 14, left: 4), width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2E5A27), shape: BoxShape.circle)) else Container(margin: const EdgeInsets.only(top: 2, right: 12), width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF2E5A27).withValues(alpha: 0.1), shape: BoxShape.circle), child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF2E5A27), fontSize: 12, fontWeight: FontWeight.bold))),
                      Expanded(child: Text(listItems[index], style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF4E342E), height: 1.6, fontWeight: FontWeight.w500))),
                    ],
                  ),
                );
              }),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: contentText.toString().split('\n').map((para) {
                if (para.trim().isEmpty) return const SizedBox(height: 8);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    para,
                    style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF4E342E), height: 1.7, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit), label: const Text('Edit')), const SizedBox(width: 8), TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('Hapus', style: TextStyle(color: Colors.red)))]),
            ),
        ],
      ),
    );
  }
}

class PondokKnowledgeEditPage extends StatefulWidget {
  const PondokKnowledgeEditPage({super.key, this.item, this.index});
  final Map<String, dynamic>? item;
  final int? index;

  @override
  State<PondokKnowledgeEditPage> createState() => _PondokKnowledgeEditPageState();
}

class _PondokKnowledgeEditPageState extends State<PondokKnowledgeEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _descCtrl;
  String _contentType = 'paragraph';
  String _imagePath = '';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item?['title'] ?? '');
    _contentCtrl = TextEditingController(text: widget.item?['content'] ?? '');
    _descCtrl = TextEditingController(text: widget.item?['description'] ?? '');
    _contentType = widget.item?['type'] ?? 'paragraph';
    _imagePath = widget.item?['imagePath'] ?? '';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final newList = List<Map<String, dynamic>>.from(provider.pondokKnowledgeList);
    final newItem = {'title': _titleCtrl.text.trim(), 'content': _contentCtrl.text.trim(), 'description': _descCtrl.text.trim(), 'type': _contentType, 'imagePath': _imagePath};
    if (widget.index == null) {
      newList.add(newItem);
    } else {
      newList[widget.index!] = newItem;
    }
    provider.updatePondokKnowledge(newList);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(widget.item == null ? 'Tambah Materi' : 'Edit Materi'), actions: [IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded, size: 28))]),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Judul *'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Keterangan Singkat')),
            const SizedBox(height: 24),
            const Text('Format Tampilan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E5A27))),
            const SizedBox(height: 8),
            Row(
              children: [
                _typeBtn('paragraph', 'Teks'),
                const SizedBox(width: 8),
                _typeBtn('bullet', 'Poin'),
                const SizedBox(width: 8),
                _typeBtn('number', 'Angka'),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(controller: _contentCtrl, maxLines: 10, decoration: const InputDecoration(labelText: 'Isi Konten *', alignLabelWithHint: true, hintText: 'Gunakan baris baru (Enter) untuk memisahkan poin.'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
            const SizedBox(height: 24),
            const Text('Foto Ilustrasi (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            _buildImagePicker(),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String type, String label) {
    final active = _contentType == type;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: active,
        onSelected: (s) => setState(() => _contentType = type),
        selectedColor: const Color(0xFF2E5A27).withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () async {
        final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (file != null) setState(() => _imagePath = file.path);
      },
      child: Container(
        height: 150,
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: _imagePath.isNotEmpty
            ? Stack(fit: StackFit.expand, children: [ClipRRect(borderRadius: BorderRadius.circular(16), child: _imagePath.startsWith('http') ? Image.network(_imagePath, fit: BoxFit.cover) : Image.file(File(_imagePath), fit: BoxFit.cover)), Positioned(top: 8, right: 8, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: () => setState(() => _imagePath = ''))))])
            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: Colors.grey), SizedBox(height: 8), Text('Klik untuk unggah foto', style: TextStyle(color: Colors.grey, fontSize: 11))]),
      ),
    );
  }
}
