import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ongea/core/providers/app_providers.dart';
import 'package:ongea/main.dart';

void main() {
  Future<void> openAppInDemo(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseReadyProvider.overrideWithValue(false)],
        child: const OngeaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explorer la démo'));
    await tester.pumpAndSettle();
  }

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
    expect(find.text('Explorer la démo'), findsOneWidget);
    expect(find.text('Se connecter'), findsNothing);
    expect(find.text('Adresse e-mail'), findsNothing);
  });

  testWidgets('le mode démo masque les actions qui ne sont pas disponibles', (
    tester,
  ) async {
    await openAppInDemo(tester);

    expect(
      find.text('Mode démo · exemples locaux en lecture seule.'),
      findsOneWidget,
    );
    expect(find.text('Appels'), findsNothing);
    expect(find.text('Nouvelle discussion'), findsNothing);
    expect(find.byTooltip('Options de la discussion'), findsNothing);

    await tester.tap(find.text('Aya Mukendi'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Appel audio'), findsNothing);
    expect(find.byTooltip('Appel vidéo'), findsNothing);
    expect(find.text('Écrire un message'), findsNothing);
    expect(
      find.textContaining('Mode démo : les messages sont des exemples.'),
      findsOneWidget,
    );
  });
}
