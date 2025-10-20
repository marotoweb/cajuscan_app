// lib/cashew_launcher.dart
import 'package:url_launcher/url_launcher.dart';
import 'fatura_model.dart';
import 'settings_service.dart'; // Importa o serviço de definições

class CashewLauncher {
  // Instancia o serviço de definições para poder consultar as preferências do utilizador.
  final SettingsService _settingsService = SettingsService();

  Future<void> launchCashew({
    required Fatura fatura,
    required String category,
    required String? subcategory,
    required String title,
  }) async {
    // 1. Consulta o serviço para saber se o utilizador quer confirmar no Cashew.
    final bool useConfirmationRoute = await _settingsService.getConfirmOnCashew();

    // 2. Decide qual o endpoint a usar com base na preferência do utilizador.
    final String endpoint = useConfirmationRoute ? 'addTransactionRoute' : 'addTransaction';

    // 3. Constrói o mapa de parâmetros da query, garantindo que o valor é negativo.
    final Map<String, String> queryParams = {
      'amount': (-fatura.valorTotal).toStringAsFixed(2), // Garante valor negativo e 2 casas decimais
      'date': fatura.data.toIso8601String().split('T').first, // Formato AAAA-MM-DD
      'title': title,
      'notes': 'Fatura importada via CajuScan\nNIF: ${fatura.nifComerciante}',
    };

    // 4. Adiciona a categoria e subcategoria apenas se não estiverem vazias.
    // O Cashew ignora categorias vazias e permite ao utilizador selecionar na app.
    if (category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (subcategory != null && subcategory.isNotEmpty) {
      queryParams['subcategory'] = subcategory;
    }

    // 5. Constrói o URI final com todos os componentes.
    final uri = Uri(
      scheme: 'https',
      host: 'cashewapp.web.app',
      path: endpoint, // Usa o endpoint dinâmico
      queryParameters: queryParams,
    );

    // 6. Tenta abrir o URL, lançando uma exceção clara em caso de falha.
    if (await canLaunchUrl(uri)) {
      // Usa o modo 'externalApplication' para garantir que abre noutra app e não num webview.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Não foi possível abrir o Cashew. Verifique se a aplicação está instalada e configurada para abrir links.');
    }
  }
}
