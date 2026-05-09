// lib/file_scanner_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:image/image.dart' as img;

class FileScannerService {
  /// Orquestra a seleção e a leitura do código, independentemente do formato
  Future<String?> selectAndScan(BuildContext context) async {
    debugPrint('==> Iniciando selectAndScan');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.single.path == null) return null;

    debugPrint('==> Ficheiro selecionado: ${result.files.single.path}');

    // Feedback visual
    if (context.mounted) _showLoading(context);

    // Pequeno delay para garantir que o CircularProgressIndicator aparece
    await Future.delayed(const Duration(milliseconds: 150));

    final filePath = result.files.single.path!;
    final extension = result.files.single.extension?.toLowerCase();

    try {
      String? qrData;

      // Decisão de processamento baseada na extensão
      if (extension == 'pdf') {
        debugPrint('==> A processar PDF: $filePath');
        qrData = await _scanPdf(filePath);
      } else {
        debugPrint('==> A processar Imagem: $filePath');
        qrData = await _scanImage(filePath);
      }

      debugPrint('==> Resultado final do scan: $qrData');
      if (context.mounted) Navigator.of(context).pop();
      return qrData;
    } catch (e) {
      debugPrint('==> Erro crítico no FileScannerService: $e');
      if (context.mounted) Navigator.of(context).pop();
      return null;
    }
  }

  /// Lê QR code de uma imagem com resolução dinâmica usando Isolate
  Future<String?> _scanImage(String path) async {
    final Uint8List fileBytes = await File(path).readAsBytes();

    return await compute(_processImageDynamicIsolate, fileBytes);
  }

  /// Lê QR code de um PDF com escalas dinâmicas usando Isolate para o processamento de imagem
  Future<String?> _scanPdf(String path) async {
    final document = await PdfDocument.openFile(path);

    // Analisamos as primeiras páginas (limitado a 5 por performance e memória)
    final totalPages = document.pagesCount;
    final pagesToScan = totalPages > 5 ? 5 : totalPages;

    // Escalas dinâmicas para renderização de páginas PDF
    // 1.5 a 2.0: Ideal para PDFs digitais limpos
    // 3.0: Equilibrado
    // 5.0: Necessário para QR codes muito densos
    final scales = [1.5, 2.5, 4.0, 5.0];

    for (var i = 1; i <= pagesToScan; i++) {
      debugPrint('==> Analisando página $i de $totalPages');
      final page = await document.getPage(i);

      for (var scale in scales) {
        debugPrint('==> A tentar escala $scale na página $i');

        final pageImage = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.jpeg,
          quality: 100,
        );

        if (pageImage != null) {
          // Processamos cada renderização pesada num Isolate
          final result = await compute(
            _processSingleImageIsolate,
            pageImage.bytes,
          );

          if (result != null) {
            debugPrint('==> QR Code encontrado na página $i com escala $scale');
            await page.close();
            await document.close();
            return result;
          }
        }
      }
      await page.close();
    }

    await document.close();
    return null;
  }

  /// Decodifica uma imagem usando luminância para melhorar a leitura de QR codes
  static String? _decodeWithLuminance(img.Image image) {
    final luminanceImage = image.convert(numChannels: 1);
    final result = zx.readBarcode(
      luminanceImage.toUint8List(),
      DecodeParams(
        format: Format.qrCode,
        width: luminanceImage.width,
        height: luminanceImage.height,
      ),
    );
    return (result.isValid && result.text != null) ? result.text : null;
  }

  /// Processa as várias resoluções de uma imagem de galeria numa thread separada
  static String? _processImageDynamicIsolate(Uint8List bytes) {
    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return null;

    final imageBase = img.bakeOrientation(originalImage);
    final targetWidths = [800, 1200, 1600];

    for (var width in targetWidths) {
      img.Image resized;
      if (imageBase.width > width) {
        resized = img.copyResize(imageBase, width: width);
      } else {
        resized = imageBase;
      }

      final text = _decodeWithLuminance(resized);
      if (text != null) return text;
      if (imageBase.width <= width) break;
    }
    return null;
  }

  /// Processa uma única imagem (render do PDF) numa thread separada
  static String? _processSingleImageIsolate(Uint8List bytes) {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;
    return _decodeWithLuminance(image);
  }
  
  /// Exibe um indicador de carregamento modal durante o processamento
  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }
}
