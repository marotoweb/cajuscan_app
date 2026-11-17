import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cajuscan_app/about_page.dart';
import 'package:cajuscan_app/settings_page.dart';

void main() {
  testWidgets(
    'Sobre CajuScan fica sempre visível no footer e abre a página Sobre',
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
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      final textFinder = find.text('Sobre CajuScan');
      expect(textFinder, findsOneWidget);

      final tileFinder = find
          .ancestor(of: textFinder, matching: find.byType(ListTile))
          .first;
      final tileRect = tester.getRect(tileFinder);
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

      // Alvo de toque mínimo recomendado pelo Android (48 dp).
      expect(tileRect.height, greaterThanOrEqualTo(48));
      // Totalmente visível desde o início, sem necessidade de scroll.
      expect(tileRect.top, greaterThanOrEqualTo(0));
      expect(tileRect.bottom, lessThanOrEqualTo(screen.height));
      // Está fora da lista rolável (footer fixo).
      expect(
        find.ancestor(of: textFinder, matching: find.byType(ListView)),
        findsNothing,
      );

      await tester.tap(textFinder);
      await tester.pumpAndSettle();
      expect(find.byType(AboutPage), findsOneWidget);
    },
  );
}
