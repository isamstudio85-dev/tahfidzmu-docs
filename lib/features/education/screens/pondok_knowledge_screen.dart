import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class PondokKnowledgeScreen extends StatefulWidget {
  const PondokKnowledgeScreen({super.key});

  @override
  State<PondokKnowledgeScreen> createState() => _PondokKnowledgeScreenState();
}

class _PondokKnowledgeScreenState extends State<PondokKnowledgeScreen> {
  // Hardcoded defaults are only used if the database has never been initialized.
  // Once the admin interacts (or initializes), it will save to Firestore.
  final List<Map<String, dynamic>> _initialDefaultSamples = [
    {
      'title': 'Mars Pondok Pesantren',
      'content': 'Wahai santri baitullah, bersatu teguh jaya...\nMenuntut ilmu berakhlak mulia, membela agama bangsa...\nKeikhlasan di dada, kesederhanaan dalam jiwa...',
      'type': 'paragraph',
      'description': 'Wajib dihafal oleh seluruh santri baru pada semester pertama.',
      'imagePath': '',
    },
    {
      'title': 'Panca Jiwa Pondok',
      'content': 'Keikhlasan\nKesederhanaan\nBerdikari (Kesanggupan Menolong Diri Sendiri)\nUkhuwah Islamiyah (Persaudaraan yang Islami)\nKebebasan (Bebas berpikir dan berbuat)',
      'type': 'bullet',
      'description': 'Nilai-nilai dasar filosofi kehidupan santri di pondok.',
      'imagePath': '',
    },
    {
      'title': 'Motto Pondok',
      'content': 'Berbudi Tinggi\nBerbadan Sehat\nBerpengetahuan Luas\nBerpikir Bebas',
      'type': 'number',
      'description': 'Karakter utama yang ditanamkan pada diri alumni pondok.',
      'imagePath': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize defaults in Firestore once if the collection is completely empty and uninitialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.pondokKnowledgeList.isEmpty && !provider.isPondokKnowledgeInitialized) {
        provider.initializePondokKnowledge(_initialDefaultSamples);
      }
    });
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Tentang Pondok'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 26),
              tooltip: 'Tambah Informasi',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PondokKnowledgeEditPage()),
              ),
            ),
        ],
      ),
      body: displayList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada informasi pondok.',
                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PondokKnowledgeEditPage()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Sekarang'),
                    )
                  ]
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayList.length,
              itemBuilder: (ctx, i) {
                final item = displayList[i];
                final type = item['type'] ?? 'paragraph';
                final isListType = type == 'bullet' || type == 'number';
                final contentText = item['content'] ?? '';
                final List<String> listItems = isListType 
                    ? contentText.toString().split('\n').where((s) => s.trim().isNotEmpty).toList() 
                    : [];
                final hasImage = item['imagePath'] != null && item['imagePath'].toString().isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.school_outlined, color: AppTheme.primaryGreen, size: 20),
                    ),
                    title: Text(
                      item['title'] ?? '',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                    subtitle: item['description'] != null && item['description'].toString().isNotEmpty
                        ? Text(item['description'], style: TextStyle(fontSize: 10, color: Colors.grey.shade500))
                        : null,
                    trailing: isAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 22),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PondokKnowledgeEditPage(item: item, index: i)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                onPressed: () => _deleteItem(i),
                              ),
                            ],
                          )
                        : null,
                    children: [
                      const Divider(height: 1),
                      if (hasImage)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item['imagePath'].toString().startsWith('http')
                                ? Image.network(item['imagePath'], fit: BoxFit.cover, width: double.infinity, height: 180)
                                : Image.file(File(item['imagePath']), fit: BoxFit.cover, width: double.infinity, height: 180, errorBuilder: (_,__,___) => const SizedBox()),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: isListType
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(listItems.length, (index) {
                                    final line = listItems[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (type == 'bullet')
                                            Container(
                                              margin: const EdgeInsets.only(top: 6, right: 12),
                                              width: 6, height: 6,
                                              decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                                            )
                                          else // 'number' list design
                                            Container(
                                              margin: const EdgeInsets.only(top: 1, right: 10),
                                              width: 18, height: 18,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: AppTheme.primaryGreen,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              line,
                                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade800, height: 1.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                )
                              : Text(
                                  contentText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12, 
                                    color: Colors.grey.shade800, 
                                    height: 1.6,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
  String _contentType = 'paragraph'; // Default style
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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri Foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final file = await picker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        setState(() {
          _imagePath = file.path;
        });
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final currentList = List<Map<String, dynamic>>.from(provider.pondokKnowledgeList);

    final newItem = {
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'type': _contentType,
      'imagePath': _imagePath,
    };

    if (widget.index == null) {
      currentList.add(newItem);
    } else {
      currentList[widget.index!] = newItem;
    }

    provider.updatePondokKnowledge(currentList);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.item == null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? 'Tambah Info Pondok' : 'Edit Info Pondok'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul Informasi *',
                hintText: 'Misal: Sejarah Pendirian Pondok',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v!.isEmpty ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan Singkat',
                hintText: 'Misal: Informasi sejarah untuk santri baru',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            
            // Content Type Selection
            const Text(
              'Format Penulisan Konten',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Paragraf')),
                    selected: _contentType == 'paragraph',
                    onSelected: (selected) {
                      if (selected) setState(() => _contentType = 'paragraph');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Bullet (•)')),
                    selected: _contentType == 'bullet',
                    onSelected: (selected) {
                      if (selected) setState(() => _contentType = 'bullet');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Angka (1.)')),
                    selected: _contentType == 'number',
                    onSelected: (selected) {
                      if (selected) setState(() => _contentType = 'number');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content input field
            TextFormField(
              controller: _contentCtrl,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: _contentType == 'paragraph' 
                    ? 'Isi Informasi (Paragraf) *' 
                    : (_contentType == 'bullet' ? 'Isi Informasi (Poin Bulat) *' : 'Isi Informasi (Poin Angka) *'),
                hintText: _contentType == 'paragraph'
                    ? 'Tulis deskripsi penjelasan pondok di sini...'
                    : 'Tulis setiap poin di baris baru (tekan Enter).\nContoh:\nPoin Pertama\nPoin Kedua\nPoin Ketiga',
                alignLabelWithHint: true,
              ),
              validator: (v) => v!.isEmpty ? 'Konten tidak boleh kosong' : null,
            ),
            const SizedBox(height: 24),

            // Image Picker Section
            const Text(
              'Foto / Gambar Ilustrasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _imagePath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _imagePath.startsWith('http')
                                ? Image.network(_imagePath, fit: BoxFit.cover)
                                : Image.file(File(_imagePath), fit: BoxFit.cover),
                            Positioned(
                              top: 8, right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(alpha: 0.5),
                                child: IconButton(
                                  icon: const Icon(Icons.delete_rounded, color: Colors.white),
                                  onPressed: () => setState(() => _imagePath = ''),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tambah Gambar (Opsional)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Simpan Informasi'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
