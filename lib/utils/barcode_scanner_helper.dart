import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
//import '../common/ui_theme.dart';
import 'dart:async';

/// Barkod tarayıcı için kaplama widget'ı
class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({
    super.key,
    required this.overlayColor,
    required this.borderColor,
    this.borderRadius = 10,
    this.borderWidth = 4,
    this.cutOutSize = 300,
  });

  final Color overlayColor;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final double cutOutSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tarayıcı dışındaki alanlar için kaplama
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              overlayColor,
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: cutOutSize,
                    width: cutOutSize,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Tarayıcı çerçevesi
        Center(
          child: Container(
            width: cutOutSize,
            height: cutOutSize,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: borderWidth),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Barkodu çerçeve içine yerleştirin',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Barkod tarama işlemlerini yöneten yardımcı sınıf
class BarcodeScannerHelper {
  /// Kamera ile barkod tarama işlemi
  static Future<String?> scanBarcodeWithCamera(BuildContext context) async {
    try {
      // Barkod tarama ekranını açalım
      final completer = Completer<String?>();
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Barkod Tarama'),
              backgroundColor: Colors.blue,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // İptal edildiğinde null değer döndürüyoruz
                  Navigator.of(context).pop();
                  completer.complete(null);
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.flash_on),
                  onPressed: () {
                    // Flaşı aç/kapat
                    final controller = MobileScannerController();
                    controller.toggleTorch();
                  },
                ),
              ],
            ),
            body: MobileScanner(
              controller: MobileScannerController(
                detectionSpeed: DetectionSpeed.normal,
                facing: CameraFacing.back,
              ),
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  final String barcode = barcodes.first.rawValue!;
                  Navigator.of(context).pop();
                  completer.complete(barcode);
                }
              },
              overlay: QRScannerOverlay(
                overlayColor: Colors.black.withOpacity(0.7),
                borderColor: Colors.blue,
                borderRadius: 12,
                borderWidth: 3,
                cutOutSize: 280,
              ),
            ),
          ),
        ),
      );
      
      // Eğer completer tamamlanmadıysa (kullanıcı back tuşuna bastıysa) null döndür
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      
      return await completer.future;
    } on PlatformException catch (e) {
      _showError(context, 'Kamera erişimi sağlanamadı: ${e.message}');
      return null;
    } catch (e) {
      _showError(context, 'Barkod tarama hatası: $e');
      return null;
    }
  }

  /// Tarama seçenekleri modalını göster
  static Future<void> showScanOptions(
    BuildContext context, {
    required Function() onCameraScan,
    required Function() onManualEntry,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Barkod Tarama Seçenekleri', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            // Kamera ile tarama butonu
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Kamera ile Tara'),
              subtitle: const Text('Kamerayı kullanarak barkodu tara'),
              onTap: () {
                Navigator.pop(context);
                onCameraScan();
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Colors.blue.withOpacity(0.1),
            ),
            const SizedBox(height: 8),
            // Manuel barkod girişi butonu
            ListTile(
              leading: const Icon(Icons.keyboard, color: Colors.blue),
              title: const Text('Manuel Giriş'),
              subtitle: const Text('Barkod numarasını elle gir'),
              onTap: () {
                Navigator.pop(context);
                onManualEntry();
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Colors.blue.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }

  /// Manuel barkod girişi dialog
  static Future<String?> showManualBarcodeDialog(BuildContext context) async {
    final TextEditingController barcodeController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Barkod Girişi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Barkod numarasını manuel olarak girin:'),
              const SizedBox(height: 16),
              TextField(
                controller: barcodeController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '8690000000001',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final barcode = barcodeController.text.trim();
                Navigator.of(context).pop(barcode.isNotEmpty ? barcode : null);
              },
              child: const Text('Ara'),
            ),
          ],
        );
      },
    );
    
    return result;
  }

  /// Hata mesajı göster
  static void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
