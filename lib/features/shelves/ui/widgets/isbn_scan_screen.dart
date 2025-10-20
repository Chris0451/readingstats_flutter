import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class IsbnScanScreen extends StatefulWidget {
  const IsbnScanScreen({super.key});

  @override
  State<IsbnScanScreen> createState() => _IsbnScanScreenState();
}

class _IsbnScanScreenState extends State<IsbnScanScreen> {
  final _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.ean13], // 978/979 (fisici)
  );

  bool _handled = false;
  bool _detectedFlash = false; // per colorare di verde la cornice per un attimo
  bool _torchOn = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scansiona ISBN'),
        actions: [
          IconButton(
            tooltip: 'Torcia',
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await _ctrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cutOut = _calcCutOut(constraints.biggest);
          return Stack(
            children: [
              // 1) Preview fotocamera
              Positioned.fill(
                child: MobileScanner(
                  controller: _ctrl,
                  onDetect: (cap) async {
                    if (_handled) return;
                    final raw = cap.barcodes.first.rawValue;
                    final isbn = _sanitizeIsbn(raw ?? '');
                    if (isbn == null) {
                      debugPrint('Scanner: non ISBN -> $raw');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Inquadra un codice ISBN (978/979).')),
                      );
                      return;
                    }

                    // Feedback visivo veloce
                    setState(() => _detectedFlash = true);
                    await Future.delayed(const Duration(milliseconds: 120));

                    _handled = true;
                    await _ctrl.stop();
                    if (!mounted) return;
                    debugPrint('Scanner: ISBN -> $isbn');
                    Navigator.of(context).pop(isbn);
                  },
                ),
              ),

              // 2) Overlay con maschera + cornice
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ScannerOverlayPainter(
                      cutOutRect: cutOut,
                      // verde se rilevato, altrimenti bianco tenue
                      borderColor: _detectedFlash
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.9),
                      maskColor: Colors.black.withOpacity(0.55),
                      borderRadius: 16,
                      borderWidth: 3,
                    ),
                  ),
                ),
              ),

              // 3) Istruzioni
              Positioned(
                bottom: 32,
                left: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Allinea il codice a barre nel riquadro',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Suggerimento: avvicina/ allontana per mettere a fuoco',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Riquadro centrale consigliato per codici 1D: largo ~80% della larghezza,
  /// alto 140px (regolabile).
  Rect _calcCutOut(Size size) {
    final w = size.width * 0.8;
    final h = 140.0;
    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  String? _sanitizeIsbn(String raw) {
    final s = raw.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
    if (s.length == 13 && (s.startsWith('978') || s.startsWith('979'))) return s;
    if (s.length == 10) return s;
    return null;
  }
}

/// Disegna la maschera scura con un “buco” (cutout) e la cornice arrotondata.
class _ScannerOverlayPainter extends CustomPainter {
  final Rect cutOutRect;
  final Color maskColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  _ScannerOverlayPainter({
    required this.cutOutRect,
    required this.maskColor,
    required this.borderColor,
    this.borderWidth = 3,
    this.borderRadius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Maschera scura
    final bgPath = Path()..addRect(Offset.zero & size);
    final cutOutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)));

    final mask = Path.combine(PathOperation.difference, bgPath, cutOutPath);
    final maskPaint = Paint()..color = maskColor;
    canvas.drawPath(mask, maskPaint);

    // Cornice
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      borderPaint,
    );

    // (facoltativo) piccole tacche agli angoli
    const t = 18.0;
    final r = Rect.fromLTWH(cutOutRect.left, cutOutRect.top, cutOutRect.width, cutOutRect.height);
    final p = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // angolo in alto-sx
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(t, 0), p);
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(0, t), p);
    // alto-dx
    canvas.drawLine(r.topRight, r.topRight + const Offset(-t, 0), p);
    canvas.drawLine(r.topRight, r.topRight + const Offset(0, t), p);
    // basso-sx
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(t, 0), p);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(0, -t), p);
    // basso-dx
    canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(-t, 0), p);
    canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(0, -t), p);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.cutOutRect != cutOutRect ||
        oldDelegate.maskColor != maskColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
