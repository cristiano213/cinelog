import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinelog/main.dart';

void main() {
  testWidgets('CineLog UI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CineLogApp(),
      ),
    );

    // 1. All'inizio l'app mostra il titolo (SliverAppBar è presente subito)
    expect(find.text('Scopri Film'), findsNWidgets(2));

    // 2. Aspettiamo che il FutureProvider completi e che lo spinner sparisca
    // pumpAndSettle aspetta che non ci siano più animazioni o task in corso
    await tester.pumpAndSettle();

    // 3. Ora verifichiamo che i dati siano apparsi (es. cerchiamo il titolo di un film)
    expect(find.text('Inception'), findsOneWidget);
  });
}