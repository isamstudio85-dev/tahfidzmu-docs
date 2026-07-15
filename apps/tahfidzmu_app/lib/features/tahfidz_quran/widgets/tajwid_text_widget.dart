import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tahfidz_app/core/tajwid/tajwid_types.dart';
import 'package:core_models/core_models.dart';

/// Widget yang menampilkan teks Arab Al-Quran dengan warna tajwid per-kata (word-by-word).
/// Pendekatan per-kata menjamin koneksi sambungan huruf Arab tetap utuh dan benar.
class TajwidRichText extends StatelessWidget {
  const TajwidRichText({
    super.key,
    required this.ayah,
    this.showTajwid = true,
    this.fontSize = 26,
    this.textAlign = TextAlign.right,
    this.defaultColor,
    this.onWordTap,
  });

  final AyahModel ayah;
  final bool showTajwid;
  final double fontSize;
  final TextAlign textAlign;
  final Color? defaultColor;
  final void Function(String word, String rule)? onWordTap;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      text: TextSpan(
        style: GoogleFonts.amiri(
          fontSize: fontSize,
          color: defaultColor ?? Colors.black87,
          height: 2.0,
        ),
        children: buildAyahSpans(
          ayah: ayah,
          showTajwid: showTajwid,
          defaultColor: defaultColor,
          onWordTap: onWordTap,
        ),
      ),
    );
  }

  /// Menghasilkan `List<TextSpan>` untuk satu ayat dengan pewarnaan tajwid yang sesuai.
  /// Ini diekstrak agar bisa digabungkan untuk mode mushaf (banyak ayat bersambung).
  static List<TextSpan> buildAyahSpans({
    required AyahModel ayah,
    required bool showTajwid,
    Color? defaultColor,
    void Function(String word, String rule)? onWordTap,
  }) {
    // Cek apakah ayat diawali basmalah ganda yang perlu dipotong (Ayat 1 selain Al-Fatihah)
    bool shouldStripBismillah = false;
    const String bismillahPrefix = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
    
    if (ayah.numberInSurah == 1 && 
        ayah.wordsTajweed.length > 4 && 
        ayah.wordsTajweed[0].word == 'بِسْمِ' && 
        ayah.wordsTajweed[1].word == 'ٱللَّهِ' && 
        ayah.wordsTajweed[2].word == 'ٱلرَّحْمَٰنِ' && 
        ayah.wordsTajweed[3].word == 'ٱلرَّحِيمِ') {
      shouldStripBismillah = true;
    }

    if (!showTajwid || ayah.wordsTajweed.isEmpty) {
      String displayedText = ayah.text;
      if (ayah.numberInSurah == 1 && 
          displayedText.startsWith(bismillahPrefix) && 
          displayedText.trim() != bismillahPrefix) {
        displayedText = displayedText.replaceFirst(bismillahPrefix, '').trim();
      }
      return [
        TextSpan(
          text: '$displayedText  ﴿${ayah.numberInSurah}﴾',
          style: TextStyle(color: defaultColor ?? Colors.black87),
        ),
      ];
    }

    final textSpans = <TextSpan>[];
    final int startIndex = shouldStripBismillah ? 4 : 0;

    for (int i = startIndex; i < ayah.wordsTajweed.length; i++) {
      final w = ayah.wordsTajweed[i];
      Color? ruleColor;
      if (w.rule != null) {
        final type = parseCpfairRule(w.rule!);
        if (type != null) {
          ruleColor = type.color;
        }
      }
      textSpans.add(TextSpan(
        text: w.word,
        style: TextStyle(
          color: ruleColor ?? defaultColor ?? Colors.black87,
          fontWeight: ruleColor != null ? FontWeight.w600 : FontWeight.normal,
        ),
        recognizer: (w.rule != null && onWordTap != null)
            ? (TapGestureRecognizer()..onTap = () => onWordTap(w.word, w.rule!))
            : null,
      ));
      if (i < ayah.wordsTajweed.length - 1) {
        textSpans.add(const TextSpan(text: ' '));
      }
    }
    
    // Tambahkan nomor ayat di akhir
    textSpans.add(TextSpan(
      text: '  ﴿${ayah.numberInSurah}﴾',
      style: TextStyle(color: defaultColor ?? Colors.black87),
    ));

    return textSpans;
  }
}
