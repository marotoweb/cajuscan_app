// lib/scanner_page.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'fatura_model.dart';
import 'confirmation_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  final MobileScannerController _scannerController = MobileScannerController();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (_isProcessing) return;

    final String? code = capture.barcodes.first.rawValue;

    if (code != null && code.contains("A:") && code.contains("F:")) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final fatura = Fatura.fromQrCodeString(code);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(fatura: fatura),
          ),
        );
      } catch (e) {
        if (!mounted) return; // Boa prática
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ler o QR Code: ${e.toString()}')),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanWindowSize = MediaQuery.of(context).size.width * 0.75;
    final scanWindowRect = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aponte para o QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camada 1: O Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetection,
            scanWindow: scanWindowRect,
          ),

          // Camada 2: A Sobreposição (Overlay)
          CustomPaint(painter: OverlayPainter(scanWindowRect)),

          // Camada 3: A Borda e a Animação
          Align(
            alignment: Alignment.center,
            child: CustomPaint(
              size: Size(scanWindowSize, scanWindowSize),
              painter: ScannerBorderPainter(),
              child: SizedBox(
                height: scanWindowSize,
                width: scanWindowSize,
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: scanWindowSize * _animation.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2.0,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withAlpha(128),
                                  blurRadius: 8.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Camada 4: Texto de ajuda
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Text(
                'Coloque o código QR dentro da área visivel',
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Camada 5: Indicador de processamento
          if (_isProcessing)
            Container(
              color: Colors.black.withAlpha(179),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'A processar dados...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Painter para desenhar a sobreposição com um buraco
class OverlayPainter extends CustomPainter {
  final Rect scanWindow;

  OverlayPainter(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final background = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)),
      );

    // Combina os dois paths, subtraindo o buraco do fundo
    final path = Path.combine(PathOperation.difference, background, hole);

    canvas.drawPath(path, Paint()..color = Colors.black.withAlpha(128));
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}

class ScannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(204)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const cornerLength = 30.0;
    const cornerRadius = Radius.circular(16.0);

    final path = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, cornerRadius.y)
      ..arcToPoint(
        Offset(cornerRadius.x, 0),
        radius: cornerRadius,
        clockwise: false,
      )
      ..lineTo(cornerLength, 0)
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - cornerRadius.x, 0)
      ..arcToPoint(
        Offset(size.width, cornerRadius.y),
        radius: cornerRadius,
        clockwise: false,
      )
      ..lineTo(size.width, cornerLength)
      ..moveTo(size.width, size.height - cornerLength)
      ..lineTo(size.width, size.height - cornerRadius.y)
      ..arcToPoint(
        Offset(size.width - cornerRadius.x, size.height),
        radius: cornerRadius,
        clockwise: false,
      )
      ..lineTo(size.width - cornerLength, size.height)
      ..moveTo(cornerLength, size.height)
      ..lineTo(cornerRadius.x, size.height)
      ..arcToPoint(
        Offset(0, size.height - cornerRadius.y),
        radius: cornerRadius,
        clockwise: false,
      )
      ..lineTo(0, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
