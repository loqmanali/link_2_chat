import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/core/startup/startup_gate.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('a database that cannot open shows Retry, and Retry opens it', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startupLoaderProvider.overrideWithValue(() async {
            opens++;
            if (opens == 1) throw StateError('disk full');
            return const MaterialApp(home: Text('the app'));
          }),
        ],
        child: const StartupGate(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Reset local data'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('the app'), findsOneWidget);
    expect(opens, 2);
  });
}
