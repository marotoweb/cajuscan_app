import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cajuscan_app/settings_page.dart';

void main() {
  testWidgets(
    'Sobre CajuScan pode ser revelado totalmente acima da borda inferior',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      // Rola até ao fim da lista de definições.
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      final textFinder = find.text('Sobre CajuScan', skipOffstage: false);
      expect(textFinder, findsOneWidget);

      final tileFinder = find
          .ancestor(
            of: textFinder,
            matching: find.byType(ListTile, skipOffstage: false),
          )
          .first;
      final tileRect = tester.getRect(tileFinder);
      final listRect = tester.getRect(find.byType(ListView));

      // Alvo de toque mínimo recomendado pelo Android (48 dp).
      expect(tileRect.height, greaterThanOrEqualTo(48));
      // O padding inferior permite que a linha fique afastada da borda.
      expect(tileRect.bottom, lessThanOrEqualTo(listRect.bottom - 16));
    },
  );
}
