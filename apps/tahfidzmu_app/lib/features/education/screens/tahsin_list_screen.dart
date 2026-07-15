import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TahsinListScreen extends StatefulWidget {
  const TahsinListScreen({super.key});

  @override
  State<TahsinListScreen> createState() => _TahsinListScreenState();
}

class _TahsinListScreenState extends State<TahsinListScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  
  // WIDE MODE STATE
  dynamic _selectedSection;
  String? _selectedCategoryTitle;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final String response = await rootBundle.loadString('assets/data/tahsin/list.json');
      final data = await json.decode(response);
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Belajar Tahsin')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Widget sidebar = ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: _categories.length,
      separatorBuilder: (ctx, i) => Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
      itemBuilder: (ctx, i) {
        return _CategoryAccordion(
          category: _categories[i],
          isWide: isWide,
          selectedSection: _selectedSection,
          onSectionTap: (catTitle, section) {
            if (isWide) {
              setState(() {
                _selectedSection = section;
                _selectedCategoryTitle = catTitle;
              });
            } else {
              // Mobile handled inside CategoryAccordion
            }
          },
        );
      },
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        appBar: AppBar(
          title: const Text('Tahsin & Makharijul Huruf'),
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Row(
          children: [
            // Master Sidebar
            SizedBox(
              width: 320,
              child: Container(
                decoration: BoxDecoration(border: Border(right: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200))),
                child: sidebar,
              ),
            ),
            // Detail Content
            Expanded(
              child: _selectedSection == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_filled_rounded, size: 80, color: (isDark ? AppTheme.accentGreen : AppTheme.darkGreen).withValues(alpha: 0.15)),
                          const SizedBox(height: 16),
                          const Text('Pilih materi di samping untuk mulai belajar', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : TahsinDetailPlayScreen(
                      key: ValueKey('vid_${_selectedSection['youtubeId']}'),
                      sections: const [], // Not used in wide mode detail
                      initialIndex: 0,
                      categoryTitle: _selectedCategoryTitle ?? '',
                      hideAppBar: true,
                      wideModeSection: _selectedSection,
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Belajar Tahsin'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: sidebar,
    );
  }
}

class _CategoryAccordion extends StatefulWidget {
  const _CategoryAccordion({required this.category, required this.isWide, this.selectedSection, required this.onSectionTap});
  final dynamic category;
  final bool isWide;
  final dynamic selectedSection;
  final Function(String, dynamic) onSectionTap;

  @override
  State<_CategoryAccordion> createState() => _CategoryAccordionState();
}

class _CategoryAccordionState extends State<_CategoryAccordion> {
  bool _expanded = false;
  List<dynamic> _sections = [];
  bool _loadingSub = false;

  Future<void> _loadSubItems() async {
    if (_sections.isNotEmpty) return;
    setState(() => _loadingSub = true);
    try {
      final fileName = widget.category['fileName'] ?? 'bab_${widget.category['id'].toString().padLeft(3, '0')}.json';
      final String response = await rootBundle.loadString('assets/data/tahsin/$fileName');
      final data = await json.decode(response);
      if (mounted) {
        setState(() {
          _sections = data['sections'] ?? [];
          _loadingSub = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        ListTile(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded) _loadSubItems();
          },
          leading: Icon(
            _expanded ? Icons.folder_open_rounded : Icons.folder_rounded,
            color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
            size: 20,
          ),
          title: Text(
            widget.category['title'],
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
        ),
        if (_expanded)
          if (_loadingSub)
            const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator(minHeight: 2))
          else
            ..._sections.map((s) {
              final isSelected = widget.selectedSection?['name'] == s['name'];
              return Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  dense: true,
                  selected: isSelected && widget.isWide,
                  selectedTileColor: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                  onTap: () {
                    if (widget.isWide) {
                      widget.onSectionTap(widget.category['title'], s);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TahsinDetailPlayScreen(
                            sections: _sections,
                            initialIndex: _sections.indexOf(s),
                            categoryTitle: widget.category['title'],
                          ),
                        ),
                      );
                    }
                  },
                  title: Text(
                    s['name'], 
                    style: GoogleFonts.poppins(
                      fontSize: 12, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                    ),
                  ),
                  leading: Icon(Icons.play_circle_outline, size: 16, color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen),
                ),
              );
            }),
      ],
    );
  }
}

class TahsinDetailPlayScreen extends StatefulWidget {
  const TahsinDetailPlayScreen({
    super.key,
    required this.sections,
    required this.initialIndex,
    required this.categoryTitle,
    this.hideAppBar = false,
    this.wideModeSection,
  });
  final List<dynamic> sections;
  final int initialIndex;
  final String categoryTitle;
  final bool hideAppBar;
  final dynamic wideModeSection;

  @override
  State<TahsinDetailPlayScreen> createState() => _TahsinDetailPlayScreenState();
}

class _TahsinDetailPlayScreenState extends State<TahsinDetailPlayScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // If wideModeSection is provided, use it directly (Detail view mode)
    final section = widget.wideModeSection ?? widget.sections[_currentIndex];
    final hasPrev = !widget.hideAppBar && _currentIndex > 0;
    final hasNext = !widget.hideAppBar && _currentIndex < widget.sections.length - 1;
    
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Belajar Tahsin'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.hideAppBar) ...[
                Text(
                  section['name'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24, color: isDark ? Colors.white : AppTheme.darkGreen),
                ),
                const SizedBox(height: 8),
                Text(widget.categoryTitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),
                const SizedBox(height: 20),
              ],
              
              if (!widget.hideAppBar) ...[
                // NAVIGATION HEADER (Mobile Only)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9), 
                    borderRadius: BorderRadius.circular(8), 
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: hasPrev ? (isDark ? AppTheme.accentGreen : AppTheme.darkGreen) : Colors.grey.shade400, size: 18), onPressed: hasPrev ? () => setState(() => _currentIndex--) : null),
                      Expanded(child: Center(child: Text(section['name'], style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis))),
                      IconButton(icon: Icon(Icons.arrow_forward_ios_rounded, color: hasNext ? (isDark ? AppTheme.accentGreen : AppTheme.darkGreen) : Colors.grey.shade400, size: 18), onPressed: hasNext ? () => setState(() => _currentIndex++) : null),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
  
              if (section['youtubeId'] != null) ...[
                LockedYoutubePlayer(key: ValueKey(section['youtubeId']), youtubeId: section['youtubeId']),
                const SizedBox(height: 24),
              ],
 
              if (section['definition'] != null) ...[
                Text(
                  'Penjelasan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  section['definition'], 
                  style: GoogleFonts.poppins(
                    fontSize: 14, 
                    height: 1.7, 
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 24),
              ],
  
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9), 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.copyright_rounded, color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen, size: 20),
                    const SizedBox(height: 8),
                    Text(
                      'Sumber Video: YouTube Syeikh Hamdy Habeeb\nHak Cipta & Panduan sepenuhnya milik pemilik saluran video.', 
                      style: GoogleFonts.poppins(
                        fontSize: 11, 
                        color: isDark ? Colors.white38 : Colors.grey.shade600, 
                        fontWeight: FontWeight.w500, 
                        height: 1.5,
                      ), 
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LockedYoutubePlayer extends StatefulWidget {
  const LockedYoutubePlayer({super.key, required this.youtubeId});
  final String youtubeId;

  @override
  State<LockedYoutubePlayer> createState() => _LockedYoutubePlayerState();
}

class _LockedYoutubePlayerState extends State<LockedYoutubePlayer> {
  late YoutubePlayerController _controller;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isOffline = false;
  double _progress = 0.0;
  String _currentTime = "0:00";
  String _totalTime = "0:00";

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _controller = YoutubePlayerController(
      initialVideoId: widget.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        hideControls: true, 
        disableDragSeek: true,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: false,
      ),
    )..addListener(_videoListener);
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (mounted) setState(() => _isOffline = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isOffline = true);
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
        final current = _controller.value.position;
        final total = _controller.value.metaData.duration;
        if (total.inSeconds > 0) {
          _progress = current.inSeconds / total.inSeconds;
        } else {
          _progress = 0.0;
        }
        _currentTime = _formatDuration(current);
        _totalTime = _formatDuration(total);
      });
    }
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString();
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 40),
              const SizedBox(height: 12),
              Text('Koneksi internet diperlukan\nuntuk memutar video panduan.', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Coba Lagi'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white), onPressed: () => _checkConnectivity()),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IgnorePointer(
            ignoring: true,
            child: AspectRatio(aspectRatio: 16 / 9, child: YoutubePlayer(controller: _controller, showVideoProgressIndicator: false)),
          ),
          Container(
            color: Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(_currentTime, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: LinearProgressIndicator(value: _progress, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen), minHeight: 4, borderRadius: BorderRadius.circular(2)))),
                    Text(_totalTime, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white), onPressed: () => setState(() { if (_isMuted) { _controller.unMute(); _isMuted = false; } else { _controller.mute(); _isMuted = true; } })),
                    CircleAvatar(backgroundColor: AppTheme.primaryGreen, radius: 22, child: IconButton(icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white), onPressed: () { if (_isPlaying) { _controller.pause(); } else { _controller.play(); } })),
                    IconButton(icon: const Icon(Icons.replay_rounded, color: Colors.white), onPressed: () { _controller.seekTo(Duration.zero); _controller.play(); }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
