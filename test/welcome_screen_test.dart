import 'package:biodiversidad/src/features/ar_guide/presentation/widgets/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('green welcome screen fits a narrow phone and starts AR on tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(300, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var starts = 0;
    await tester.pumpWidget(
      MaterialApp(home: WelcomeScreen(onStart: () => starts++)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Conoce a Ukumari'), findsOneWidget);
    await tester.ensureVisible(find.text('Iniciar experiencia AR'));
    await tester.tap(find.text('Iniciar experiencia AR'));
    expect(starts, 1);
  });
}
