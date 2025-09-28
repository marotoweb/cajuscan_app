// lib/cashew_launcher.dart
import 'package:url_launcher/url_launcher.dart';
import 'fatura_model.dart';
import 'settings_service.dart';

class CashewLauncher {
  final SettingsService _settingsService = SettingsService();

  Future<void> launchCashew({
    required Fatura fatura,
    required String category,
    String? subcategory,
    String? title,
  }) async {
    // --- Logica de decisão do endpoint ---
    final bool useConfirmationRoute = await _settingsService
        .getConfirmOnCashew();
    final String endpoint = useConfirmationRoute
        ? 'addTransactionRoute'
        : 'addTransaction';

    final transactionTitle = title ?? 'Despesa ${fatura.nifComerciante}';

    final Map<String, String> queryParameters = {
      'amount': (-fatura.valorTotal).toString(),
      'date': fatura.data.toIso8601String().split('T').first,
      'title': Uri.encodeComponent(transactionTitle),
      'notes': Uri.encodeComponent(
        'Fatura importada via QR Code\nNIF: ${fatura.nifComerciante}',
      ),
    };

    // Adiciona os parâmetros apenas se não estiverem vazios
    if (category.isNotEmpty) {
      queryParameters['category'] = Uri.encodeComponent(category);
    }
    if (subcategory != null && subcategory.isNotEmpty) {
      queryParameters['subcategory'] = Uri.encodeComponent(subcategory);
    }

    final uri = Uri(
      scheme: 'https',
      host: 'cashewapp.web.app',
      path: endpoint,
      queryParameters: queryParameters,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception(
        'Não foi possível abrir o Cashew. Verifique se a aplicação está instalada e configurada para abrir links.',
      );
    }
  }
}
