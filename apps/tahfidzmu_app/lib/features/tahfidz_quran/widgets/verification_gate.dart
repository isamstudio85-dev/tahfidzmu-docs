import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/qr_scanner_screen.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class VerificationGate {
  /// Directly opens the QR Scanner camera to verify physical presence.
  /// Bypasses any selection UI for maximum speed.
  static Future<Santri?> show({
    required BuildContext context,
    Santri? expectedSantri,
  }) async {
    final provider = context.read<AppProvider>();
    
    // BYPASS LOGIC: If global QR security is disabled, auto-verify
    if (!provider.pesantrenInfo.qrSecurityEnabled) {
      debugPrint("QR Security disabled: Bypassing scan.");
      return expectedSantri;
    }

    final verified = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(expectedSantri: expectedSantri),
      ),
    );

    if (verified == null) return null;
    
    // If scanner returned a full Santri object, use it. 
    // Otherwise, if it just confirmed success for expectedSantri, return that.
    return verified is Santri ? verified : expectedSantri;
  }
}
