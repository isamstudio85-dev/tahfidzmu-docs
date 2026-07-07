import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class QrScannerScreen extends StatefulWidget {
  final Santri? expectedSantri;
  final bool returnRaw;

  const QrScannerScreen({super.key, this.expectedSantri, this.returnRaw = false});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  late AnimationController _animController;
  bool _isTorchOn = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? codeValue = barcodes.first.rawValue;
    if (codeValue == null || codeValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    if (widget.returnRaw) {
      _showSuccessAndPop(codeValue);
      return;
    }

    final provider = context.read<AppProvider>();
    final santriList = provider.santriList;

    if (widget.expectedSantri != null) {
      // Verifikasi santri tertentu
      final expected = widget.expectedSantri!;
      final isMatch = codeValue == expected.id || codeValue == expected.nis;

      if (isMatch) {
        _showSuccessAndPop(expected);
      } else {
        setState(() {
          _errorMessage = "QR Code tidak cocok dengan ${expected.name}";
          _isProcessing = false;
        });
        // Reset error after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _errorMessage = null);
          }
        });
      }
    } else {
      // Cari santri dari list secara global
      final matched = santriList.firstWhere(
        (s) => s.id == codeValue || s.nis == codeValue,
        orElse: () => const Santri(id: '', name: ''),
      );

      if (matched.id.isNotEmpty) {
        _showSuccessAndPop(matched);
      } else {
        setState(() {
          _errorMessage = "Santri tidak terdaftar di pesantren ini";
          _isProcessing = false;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _errorMessage = null);
          }
        });
      }
    }
  }

  void _showSuccessAndPop(dynamic result) {
    // Tampilkan feedback visual sukses
    final message = widget.returnRaw
        ? "Scan Kartu Berhasil!"
        : "Verifikasi Berhasil: ${result is Santri ? result.name : 'Santri Cocok'}";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.expectedSantri != null ? 'Verifikasi Kehadiran' : 'Pindai Kartu Santri',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Scanner view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white60),
                      const SizedBox(height: 16),
                      Text(
                        'Kamera tidak dapat diakses.\nPastikan izin kamera telah diberikan.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Custom scanner overlay (Visual Cutout)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScannerOverlayPainter(
                    scanLinePercent: _animController.value,
                    errorMessage: _errorMessage,
                  ),
                );
              },
            ),
          ),

          // 3. Instruction details on screen bottom
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.returnRaw
                        ? "Fokuskan kamera ke QR Code & Nama Santri"
                        : (widget.expectedSantri != null
                            ? "Pindai QR Code milik:\n${widget.expectedSantri!.name}"
                            : "Arahkan kamera ke QR Code di kartu santri"),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.returnRaw
                          ? "Hindari memindai judul header kartu agar data tidak terganggu."
                          : "Musyrif wajib memverifikasi kehadiran santri secara fisik.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double scanLinePercent;
  final String? errorMessage;

  ScannerOverlayPainter({required this.scanLinePercent, this.errorMessage});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Hitung scan area size (260x260 square)
    final double scanSize = 260.0;
    final double left = (width - scanSize) / 2;
    final double top = (height - scanSize) / 2;
    final Rect scanRect = Rect.fromLTWH(left, top, scanSize, scanSize);

    // 1. Gambar overlay gelap di luar area scan
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: errorMessage != null ? 0.8 : 0.6)
      ..style = PaintingStyle.fill;

    // Path untuk menutupi seluruh screen kecuali scanRect
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // 2. Gambar frame sudut (corners)
    final Paint borderPaint = Paint()
      ..color = errorMessage != null ? Colors.redAccent : AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final double cornerLength = 24.0;

    // Kiri Atas
    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLength, top)
        ..quadraticBezierTo(left, top, left, top + cornerLength),
      borderPaint,
    );

    // Kanan Atas
    canvas.drawPath(
      Path()
        ..moveTo(left + scanSize - cornerLength, top)
        ..quadraticBezierTo(left + scanSize, top, left + scanSize, top + cornerLength),
      borderPaint,
    );

    // Kiri Bawah
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanSize - cornerLength)
        ..quadraticBezierTo(left, top + scanSize, left + cornerLength, top + scanSize),
      borderPaint,
    );

    // Kanan Bawah
    canvas.drawPath(
      Path()
        ..moveTo(left + scanSize - cornerLength, top + scanSize)
        ..quadraticBezierTo(left + scanSize, top + scanSize, left + scanSize, top + scanSize - cornerLength),
      borderPaint,
    );

    // 3. Gambar garis pemindai (scanning line) bergerak
    if (errorMessage == null) {
      final Paint linePaint = Paint()
        ..color = AppTheme.primaryGreen.withValues(alpha: 0.8)
        ..strokeWidth = 2.0;

      final double currentY = top + (scanSize * scanLinePercent);
      canvas.drawLine(
        Offset(left + 8, currentY),
        Offset(left + scanSize - 8, currentY),
        linePaint,
      );

      // Gambar glow effect di bawah/atas garis
      final Paint glowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTRB(left, currentY - 15, left + scanSize, currentY + 15));

      canvas.drawRect(
        Rect.fromLTRB(left + 8, currentY - 15, left + scanSize - 8, currentY),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanLinePercent != scanLinePercent ||
        oldDelegate.errorMessage != errorMessage;
  }
}
