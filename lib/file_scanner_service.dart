// lib/file_scanner_service.dart
import 'dart:io';
import 'dart:typed_data';
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

  /// Lê QR code de uma imagem (JPG/PNG) com resolução dinâmica
  Future<String?> _scanImage(String path) async {
    final Uint8List fileBytes = await File(path).readAsBytes();

    // Decodificar a imagem original
    img.Image? originalImage = img.decodeImage(fileBytes);
    if (originalImage == null) return null;

    // Normaliza a orientação (Exif)
    final imageBase = img.bakeOrientation(originalImage);

    // Resoluções dinâmicas para fotos
    final targetWidths = [800, 1200, 1600];

    for (var width in targetWidths) {
      debugPrint('==> A tentar scan de imagem com largura: ${width}px');

      img.Image resized;
      if (imageBase.width > width) {
        resized = img.copyResize(imageBase, width: width);
      } else {
        resized = imageBase;
      }

      // Extração de luminância (Grayscale 1-canal) para o ZXing
      final luminanceImage = resized.convert(numChannels: 1);
      final luminanceBytes = luminanceImage.toUint8List();

      final result = zx.readBarcode(
        luminanceBytes,
        DecodeParams(
          format: Format.qrCode,
          width: luminanceImage.width,
          height: luminanceImage.height,
        ),
      );

      if (result.isValid && result.text != null) {
        debugPrint('==> QR Code encontrado na imagem com ${width}px');
        return result.text;
      }

      // Se a imagem original já era menor que a próxima largura, não vale a pena tentar aumentar
      if (imageBase.width <= width) break;
    }

    return null;
  }

  /// Lê QR code de um PDF com escalas dinâmicas
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
          img.Image? image = img.decodeImage(pageImage.bytes);
          if (image != null) {
            debugPrint('==> A tentar descodificar QR Code do PDF...');

            // Extração de luminância (Grayscale 1-canal) para o ZXing
            final luminanceImage = image.convert(numChannels: 1);
            final luminanceBytes = luminanceImage.toUint8List();

            final result = zx.readBarcode(
              luminanceBytes,
              DecodeParams(
                format: Format.qrCode,
                width: luminanceImage.width,
                height: luminanceImage.height,
              ),
            );

            if (result.isValid && result.text != null) {
              debugPrint(
                '==> QR Code encontrado na página $i com escala $scale',
              );
              await page.close();
              await document.close();
              return result.text;
            }
          }
        }
      }
      await page.close();
    }

    await document.close();
    return null;
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }
}
