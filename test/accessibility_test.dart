import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/services.dart';

import 'package:cajuscan_app/about_page.dart';
import 'package:cajuscan_app/home_page.dart';
import 'package:cajuscan_app/account_editor_page.dart';
import 'package:cajuscan_app/category_editor_page.dart';
import 'package:cajuscan_app/import_export_page.dart';
import 'package:cajuscan_app/management_page.dart';
import 'package:cajuscan_app/settings_page.dart';

Future<void> _pumpPage(WidgetTester tester, Widget page) async {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'CajuScan',
    packageName: 'com.marotoweb.cajuscan_app',
    version: '1.0.11',
    buildNumber: '13',
    buildSignature: '',
  );
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pumpAndSettle();
}

void pagesTests() {
  final pages = <String, Widget>{
    'Definições': const SettingsPage(),
    'Importar / Exportar': const ImportExportPage(),
    'Sobre': const AboutPage(),
    'Gerir contas': const AccountEditorPage(),
    'Gerir categorias': const CategoryEditorPage(),
    'Gerir comerciantes': const ManagementPage(),
  };

  for (final entry in pages.entries) {
    group(entry.key, () {
      testWidgets('alvos de toque com pelo menos 48 dp', (tester) async {
        await _pumpPage(tester, entry.value);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      });

      testWidgets('botões têm etiqueta semântica', (tester) async {
        await _pumpPage(tester, entry.value);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      });

      testWidgets('texto cumpre contraste WCAG AA', (tester) async {
        await _pumpPage(tester, entry.value);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });
    });
  }
}

void _mockSharingIntent() {
  const channel = MethodChannel('receive_sharing_intent/messages');
  const events = MethodChannel('receive_sharing_intent/events-media');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'getInitialMedia') return '[]';
    return null;
  });
  messenger.setMockMethodCallHandler(events, (call) async => null);
  addTearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(events, null);
  });
}

void main() {
  homeTests();
  pagesTests();
}

void homeTests() {
  testWidgets('Home: contraste, alvos e escala de texto a 200%', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _mockSharingIntent();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Sem overflow nos botões com fonte grande.
    expect(find.text('Digitalizar fatura'), findsOneWidget);
    expect(find.text('Importar ficheiro (PDF/Foto)'), findsOneWidget);
  });
}
