import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ongea/core/providers/app_providers.dart';
import 'package:ongea/main.dart';

void main() {
  testWidgets('l’application démarre sur l’écran de connexion sans Firebase', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseReadyProvider.overrideWithValue(false)],
        child: const OngeaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ongea'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
