import 'package:flutter_test/flutter_test.dart';

import 'package:aquajex_catalogue/main.dart';

void main() {
  testWidgets('Affiche les deux boutons de tarif', (WidgetTester tester) async {
    await tester.pumpWidget(const AquajexApp());

    expect(find.text('Aquajex'), findsOneWidget);
    expect(find.text('Les Cinq Frères'), findsOneWidget);
  });
}
