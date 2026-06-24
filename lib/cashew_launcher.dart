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
    String? account,
    String? title,
  }) async {
    // Consulta o serviço para saber se o utilizador quer confirmar no Cashew.
    final bool useConfirmationRoute = await _settingsService
        .getConfirmOnCashew();
    final String endpoint = useConfirmationRoute
        ? 'addTransactionRoute'
        : 'addTransaction';

    // Consulta se o utilizador tem ativa a opção de anexar metadados fiscais completos nas notas
    final bool sendFiscalInfo = await _settingsService.getSendFiscalInfo();

    // Constrói o mapa de parâmetros da query, garantindo que o valor é negativo.
    final transactionTitle = title ?? 'Despesa ${fatura.merchantNif}';

    final String notasFinais =
        'Fatura importada via QR Code\n'
        '${sendFiscalInfo ? fatura.toString() : 'NIF: ${fatura.merchantNif}'}';

    final Map<String, String> queryParameters = {
      'amount': (-fatura.totalAmount).toString(),
      'date': fatura.date.toIso8601String(),
      'title': transactionTitle,
      'notes': notasFinais,
    };

    // Adiciona os parâmetros apenas se não estiverem vazios
    if (category.isNotEmpty) {
      queryParameters['category'] = category;
    }
    if (subcategory != null && subcategory.isNotEmpty) {
      queryParameters['subcategory'] = subcategory;
    }

    // Injetar a conta nos parâmetros que o Cashew vai ler
    if (account != null && account.isNotEmpty) {
      queryParameters['account'] = account;
    }

    // Constrói o URI final para abrir o Cashew com os parâmetros necessários.
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
