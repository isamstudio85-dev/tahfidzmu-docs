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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Belajar Tahsin'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(child: Text('Materi belum tersedia.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TahsinSubListScreen(
                              fileName: cat['fileName'] ?? 'bab_${cat['id'].toString().padLeft(3, '0')}.json',
                              title: cat['title'],
                            ),
                          ),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(cat['icon']),
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          cat['title'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: cat['description'] != null && cat['description'].isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  cat['description'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              )
                            : null,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'record_voice_over':
        return Icons.record_voice_over_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }
}

class TahsinSubListScreen extends StatefulWidget {
  const TahsinSubListScreen({super.key, required this.fileName, required this.title});
  final String fileName;
  final String title;

  @override
  State<TahsinSubListScreen> createState() => _TahsinSubListScreenState();
}

class _TahsinSubListScreenState extends State<TahsinSubListScreen> {
  dynamic _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubItems();
  }

  Future<void> _loadSubItems() async {
    try {
      final String response = await rootBundle.loadString('assets/data/tahsin/${widget.fileName}');
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
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Gagal memuat materi.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: (_data['sections'] as List).length,
                        itemBuilder: (ctx, i) {
                          final section = _data['sections'][i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade100),
                            ),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TahsinDetailPlayScreen(
                                    sections: _data['sections'] as List<dynamic>,
                                    initialIndex: i,
                                    categoryTitle: widget.title,
                                  ),
                                ),
                              ),
                              leading: section['letters'] != null
                                  ? Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        section['letters'],
                                        style: GoogleFonts.amiri(
                                          fontSize: 22,
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_circle_outline_rounded,
                                        color: AppTheme.primaryGreen,
                                        size: 20,
                                      ),
                                    ),
                              title: Text(
                                section['name'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: section['definition'] != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        section['definition'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : null,
                              trailing: const Icon(
                                Icons.play_arrow_rounded,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class TahsinDetailPlayScreen extends StatefulWidget {
  const TahsinDetailPlayScreen({
    super.key,
    required this.sections,
    required this.initialIndex,
    required this.categoryTitle,
  });
  final List<dynamic> sections;
  final int initialIndex;
  final String categoryTitle;

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
    final section = widget.sections[_currentIndex];
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < widget.sections.length - 1;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Belajar Tahsin'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.categoryTitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // NAVIGATION HEADER BAR WITH ARROWS
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Previous Button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: hasPrev ? AppTheme.primaryGreen : Colors.grey.shade300,
                      size: 20,
                    ),
                    onPressed: hasPrev
                        ? () {
                            setState(() {
                              _currentIndex--;
                            });
                          }
                        : null,
                  ),
                  
                  // Centered Title and Arabic Letter
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            section['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (section['letters'] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            section['letters'],
                            style: GoogleFonts.amiri(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Next Button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: hasNext ? AppTheme.primaryGreen : Colors.grey.shade300,
                      size: 20,
                    ),
                    onPressed: hasNext
                        ? () {
                            setState(() {
                              _currentIndex++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Only load the player if the YouTube ID exists (Placed above definition)
            if (section['youtubeId'] != null) ...[
              LockedYoutubePlayer(key: ValueKey(section['youtubeId']), youtubeId: section['youtubeId']),
              const SizedBox(height: 20),
            ],


            const SizedBox(height: 24),
            
            // Video Credits and Copyright Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.copyright_rounded, color: AppTheme.primaryGreen, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    'Sumber Video: YouTube Syeikh Hamdy Habeeb\nHak Cipta & Panduan sepenuhnya milik pemilik saluran video.',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade500,
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
        hideControls: true, // Sembunyikan kontrol asli
        disableDragSeek: true, // Cegah geser manual
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: false,
      ),
    )..addListener(_videoListener);
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
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
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white70,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Koneksi internet diperlukan\nuntuk memutar video panduan.',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  _checkConnectivity();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Pembungkus Video dengan IgnorePointer untuk Mencegah Interaksi Klik Langsung ke YouTube
          IgnorePointer(
            ignoring: true,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: false,
              ),
            ),
          ),
          
          // KONTROL CUSTOM KITA SENDIRI
          Container(
            color: Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Progress Bar
                Row(
                  children: [
                    Text(
                      _currentTime,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      _totalTime,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mute / Unmute
                    IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_isMuted) {
                            _controller.unMute();
                            _isMuted = false;
                          } else {
                            _controller.mute();
                            _isMuted = true;
                          }
                        });
                      },
                    ),
                    // Play / Pause
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen,
                      radius: 22,
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (_isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        },
                      ),
                    ),
                    // Replay / Reset
                    IconButton(
                      icon: const Icon(
                        Icons.replay_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _controller.seekTo(Duration.zero);
                        _controller.play();
                      },
                    ),
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
