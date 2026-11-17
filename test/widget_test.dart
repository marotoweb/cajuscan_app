import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cajuscan_app/about_page.dart';
import 'package:cajuscan_app/import_export_page.dart';
import 'package:cajuscan_app/settings_page.dart';

void _configureView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.625;
  // Simula a barra de navegação do sistema (48 dp).
  tester.view.padding = const FakeViewPadding(bottom: 48 * 2.625);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
}

Future<void> _pumpSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'CajuScan',
    packageName: 'com.marotoweb.cajuscan_app',
    version: '1.0.11',
    buildNumber: '12',
    buildSignature: '',
  );
  _configureView(tester);

  await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Sobre CajuScan fica sempre visível no footer', (tester) async {
    await _pumpSettings(tester);

    final textFinder = find.text('Sobre CajuScan');
    expect(textFinder, findsOneWidget);

    final tileFinder = find
        .ancestor(of: textFinder, matching: find.byType(ListTile))
        .first;
    final tileRect = tester.getRect(tileFinder);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    const navBarHeight = 48.0;

    // Alvo de toque mínimo recomendado pelo Android (48 dp).
    expect(tileRect.height, greaterThanOrEqualTo(48));
    // Totalmente visível desde o início e acima da barra de navegação.
    expect(tileRect.top, greaterThanOrEqualTo(0));
    expect(tileRect.bottom, lessThanOrEqualTo(screen.height - navBarHeight));
    // Está fora da lista rolável (footer fixo).
    expect(
      find.ancestor(of: textFinder, matching: find.byType(ListView)),
      findsNothing,
    );

    await tester.tap(textFinder);
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);
  });

  testWidgets('Importar / Exportar abre a página com as três opções', (
    tester,
  ) async {
    await _pumpSettings(tester);

    // Rola até ao fim da lista para revelar a entrada.
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    for (var i = 0; i < 3; i++) {
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
    }

    final entryFinder = find.text('Importar / Exportar');
    expect(entryFinder, findsOneWidget);

    await tester.tap(entryFinder);
    await tester.pumpAndSettle();

    expect(find.byType(ImportExportPage), findsOneWidget);
    expect(find.text('Exportar dados (Backup)'), findsOneWidget);
    expect(find.text('Importar dados (Restauro)'), findsOneWidget);
    expect(find.text('Importar dados do Cashew'), findsOneWidget);
  });

  testWidgets(
    'A lista de definições pode ser revelada totalmente acima da barra de navegação',
    (tester) async {
      await _pumpSettings(tester);

      // Rola até ao fim da lista (repetir porque a altura do conteúdo pode
      // estabilizar após o primeiro layout).
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      for (var i = 0; i < 3; i++) {
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
      }

      final textFinder = find.text('Importar / Exportar');
      expect(textFinder, findsOneWidget);

      final tileFinder = find
          .ancestor(of: textFinder, matching: find.byType(ListTile))
          .first;
      final tileRect = tester.getRect(tileFinder);
      final listRect = tester.getRect(find.byType(ListView).first);

      // O último item fica inteiro dentro da área rolável, acima do footer.
      expect(tileRect.top, greaterThanOrEqualTo(listRect.top));
      expect(tileRect.bottom, lessThanOrEqualTo(listRect.bottom));
    },
  );
}
