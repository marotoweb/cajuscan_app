import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cajuscan_app/about_page.dart';
import 'package:cajuscan_app/settings_page.dart';

void main() {
  testWidgets('Sobre CajuScan está sempre acessível na AppBar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'CajuScan',
      packageName: 'com.marotoweb.cajuscan_app',
      version: '1.0.11',
      buildNumber: '12',
      buildSignature: '',
    );
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    final infoFinder = find.byTooltip('Sobre CajuScan');
    expect(infoFinder, findsOneWidget);

    // Alvo de toque mínimo recomendado pelo Android (48x48 dp).
    final infoRect = tester.getRect(infoFinder);
    expect(infoRect.width, greaterThanOrEqualTo(48));
    expect(infoRect.height, greaterThanOrEqualTo(48));

    // Está na AppBar, não na lista rolável.
    expect(
      find.ancestor(of: infoFinder, matching: find.byType(AppBar)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: infoFinder, matching: find.byType(ListView)),
      findsNothing,
    );

    await tester.tap(infoFinder);
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);
  });

  testWidgets(
    'Importar dados do Cashew pode ser revelado totalmente acima da borda inferior',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'CajuScan',
        packageName: 'com.marotoweb.cajuscan_app',
        version: '1.0.11',
        buildNumber: '12',
        buildSignature: '',
      );
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.625;
      // Simula a barra de navegação do sistema (48 dp).
      tester.view.padding = const FakeViewPadding(bottom: 48 * 2.625);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      // Rola até ao fim da lista de definições (repetir porque a altura do
      // conteúdo pode estabilizar após o primeiro layout).
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      for (var i = 0; i < 3; i++) {
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
      }

      final textFinder = find.text('Importar dados do Cashew');
      expect(textFinder, findsOneWidget);

      final tileFinder = find
          .ancestor(of: textFinder, matching: find.byType(ListTile))
          .first;
      final tileRect = tester.getRect(tileFinder);
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      const navBarHeight = 48.0;

      // Depois de rolar, a última opção fica inteira acima da barra de
      // navegação do sistema.
      expect(tileRect.top, greaterThanOrEqualTo(0));
      expect(tileRect.bottom, lessThanOrEqualTo(screen.height - navBarHeight));
    },
  );
}
