// lib/cashew_launcher.dart
import 'package:url_launcher/url_launcher.dart';
import 'fatura_model.dart';
import 'settings_service.dart';

class CashewLauncher {
  // Instancia o serviço de definições para poder consultar as preferências do utilizador.
  final SettingsService _settingsService = SettingsService();

  Future<void> launchCashew({
    required Fatura fatura,
    required String category,
    String? subcategory,
    String? title,
  }) async {
    // Consulta o serviço para saber se o utilizador quer confirmar no Cashew.
    final bool useConfirmationRoute = await _settingsService
        .getConfirmOnCashew();
    final String endpoint = useConfirmationRoute
        ? 'addTransactionRoute'
        : 'addTransaction';

    // Constrói o mapa de parâmetros da query, garantindo que o valor é negativo.
    // Os valores aqui estão no seu formato original (ex: "Alimentação").
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

    // Constrói o URI final usando o construtor Uri.
    // Este construtor trata AUTOMATICAMENTE da codificação de caracteres especiais (como 'ã', 'ç', espaços, etc.)
    // nos valores do mapa 'queryParameters'.
    final uri = Uri(
      scheme: 'https',
      host: 'cashewapp.web.app',
      path: endpoint,
      queryParameters: queryParameters,
    );

    // Tenta abrir o URL, lançando uma exceção clara em caso de falha.
    if (await canLaunchUrl(uri)) {
      // Usa o modo 'externalApplication' para garantir que abre noutra app e não num webview.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception(
        'Não foi possível abrir o Cashew. Verifique se a aplicação está instalada e configurada para abrir links.',
      );
    }
  }
}
