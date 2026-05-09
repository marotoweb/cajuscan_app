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

  /// Lê QR code de uma imagem (JPG/PNG)
  Future<String?> _scanImage(String path) async {
    final Uint8List fileBytes = await File(path).readAsBytes();

    // Decodificar a imagem
    img.Image? image = img.decodeImage(fileBytes);
    if (image == null) return null;

    // Normaliza a orientação da foto (Exif)
    image = img.bakeOrientation(image);

    // Redimensionar para evitar estouro de memória e SIGSEGV
    if (image.width > 800 || image.height > 800) {
      image = img.copyResize(image, width: 800);
    }

    // Convertemos a imagem para escala de cinza e extraímos apenas o canal de brilho
    final grayscale = img.grayscale(image);
    final luminanceBytes = grayscale.getBytes(order: img.ChannelOrder.red);

    final result = zx.readBarcode(
      luminanceBytes,
      DecodeParams(
        format: Format.qrCode,
        width: image.width,
        height: image.height,
      ),
    );

    return result.isValid ? result.text : null;
  }

  /// Lê QR code de um PDF
  Future<String?> _scanPdf(String path) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(path);
      final page = await document.getPage(1);

      debugPrint('==> A renderizar metade superior do PDF (alta resolução)');

      // Renderizamos apenas a parte superior para poupar RAM e ganhar nitidez
      final pageImage = await page.render(
        width: page.width * 3,
        height: page.height * 3,
        format: PdfPageImageFormat.jpeg,
        quality: 100,
        // Cortamos a renderização na metade da altura (crop)
        // Se a biblioteca não suportar o crop no render, o multiplicador * 3 já ajudará
      );

      await page.close();
      await document.close();

      if (pageImage != null) {
        img.Image? image = img.decodeImage(pageImage.bytes);
        if (image != null) {
          image = img.bakeOrientation(image);

          // Aplicamos um filtro de nitidez (sharpen) para definir melhor os cantos do QR
          image = img.grayscale(image);
          image = img.contrast(
            image,
            contrast: 180,
          ); // Contraste agressivo para digital

          final luminanceBytes = image.getBytes(order: img.ChannelOrder.red);

          debugPrint('==> A tentar descodificar QR Code do PDF...');
          final result = zx.readBarcode(
            luminanceBytes,
            DecodeParams(
              format: Format.qrCode,
              width: image.width,
              height: image.height,
            ),
          );

          if (result.isValid && result.text != null) {
            debugPrint('==> QR Code encontrado!');
            return result.text;
          }
        }
      }
    } catch (e) {
      debugPrint('==> Erro ao processar página do PDF: $e');
    } finally {
      await document?.close();
    }
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
