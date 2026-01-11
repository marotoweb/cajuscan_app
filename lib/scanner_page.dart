// lib/scanner_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
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

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Configuração da linha vermelha animada
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Ajustamos o Tween para 0.01 a 0.95 para a barra não "bater" nos cantos e causar o piscar
    _animation = Tween<double>(begin: 0, end: 0.99).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDetection(Code result) {
    if (_isProcessing || result.text == null) return;

    final String code = result.text!;

    // Validação de faturas portuguesas (ATCUD/QR)
    if (code.contains("A:") && code.contains("F:")) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final fatura = Fatura.fromQrCodeString(code);
        // Usamos push para permitir voltar ao scanner se necessário
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => ConfirmationPage(fatura: fatura),
              ),
            )
            .then((_) {
              if (mounted) {
                setState(() => _isProcessing = false);
              }
            });
      } catch (e) {
        debugPrint('Erro ao ler QR: $e');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isProcessing = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define o tamanho da janela de scan (75% da largura)
    final scanWindowSize = screenWidth * 0.75;

    // Retângulo centralizado para o Overlay e para o Crop do motor de scan
    final scanWindowRect = Rect.fromCenter(
      center: Offset(screenWidth / 2, screenHeight / 2),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Aponte para o código QR'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camada 1: O Scanner (ZXing)
          ReaderWidget(
            onScan: _handleDetection,

            // Desativamos todas as decorações nativas
            showFlashlight: false,
            showGallery: false,
            showToggleCamera: false,

            // Desativar o zoom traz uma melhoria de performance marginal
            allowPinchZoom: false,

            // Define a área de processamento para 75% da largura/altura disponível
            cropPercent: 0.75,

            // Desactivar janela default do ZXing, usamos a nossa camada
            showScannerOverlay: false,

            // Delay entre scans para evitar múltiplas leituras rápidas
            scanDelay: const Duration(milliseconds: 500),
          ),

          // Camada 2: Overlay (Fundo escurecido com recorte)
          RepaintBoundary(
            child: CustomPaint(painter: OverlayPainter(scanWindowRect)),
          ),

          // Camada 3: Borda e linha animada
          Center(
            child: SizedBox(
              height: scanWindowSize,
              width: scanWindowSize,
              child: Stack(
                children: [
                  // As bordas com ângulo arredondado invertido
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: ScannerBorderPainter()),
                    ),
                  ),
                  // Linha Vermelha Animada
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: scanWindowSize * _animation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3.0,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.6),
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

          // Camada 4: Texto de ajuda
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Text(
                'Coloque o código QR dentro da área visível',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  shadows: const [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
          ),

          // Camada 5: Indicador de processamento
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
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
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);

    // 1. Criamos o fundo total
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 2. Criamos o caminho do "buraco" com cantos invertidos
    const radius = 16.0;
    final holePath = Path();

    // Desenho manual do contorno do buraco para permitir arcos invertidos
    holePath.moveTo(scanWindow.left, scanWindow.top + radius);

    // Superior Esquerdo (Invertido)
    holePath.arcToPoint(
      Offset(scanWindow.left + radius, scanWindow.top),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    holePath.lineTo(scanWindow.right - radius, scanWindow.top);

    // Superior Direito (Invertido)
    holePath.arcToPoint(
      Offset(scanWindow.right, scanWindow.top + radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    holePath.lineTo(scanWindow.right, scanWindow.bottom - radius);

    // Inferior Direito (Invertido)
    holePath.arcToPoint(
      Offset(scanWindow.right - radius, scanWindow.bottom),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    holePath.lineTo(scanWindow.left + radius, scanWindow.bottom);

    // Inferior Esquerdo (Invertido)
    holePath.arcToPoint(
      Offset(scanWindow.left, scanWindow.bottom - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    holePath.close();

    // 3. Subtraímos o buraco do fundo
    canvas.drawPath(
      Path.combine(PathOperation.difference, backgroundPath, holePath),
      backgroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) =>
      oldDelegate.scanWindow != scanWindow;
}

// --- DESENHO DOS CANTOS BRANCOS DA MOLDURA ---
class ScannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    const cornerLength = 30.0;
    const radius = 16.0; // Raio da curva invertida

    final path = Path();

    // Superior Esquerdo
    path.moveTo(0, cornerLength);
    path.lineTo(0, radius);
    path.arcToPoint(
      const Offset(radius, 0),
      radius: const Radius.circular(radius),
      clockwise: false, // Curva para fora (invertida)
    );
    path.lineTo(cornerLength, 0);

    // Superior Direito
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width, cornerLength);

    // Inferior Direito
    path.moveTo(size.width, size.height - cornerLength);
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width - cornerLength, size.height);

    // Inferior Esquerdo
    path.moveTo(cornerLength, size.height);
    path.lineTo(radius, size.height);
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(0, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
