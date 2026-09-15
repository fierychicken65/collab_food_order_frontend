import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collab_food_order_frontend/main.dart';

void main() {
  testWidgets('CollabFoodApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CollabFoodApp(),
      ),
    );

    // Verify that the title and ordering options render
    expect(find.text('Collab Food'), findsOneWidget);
    expect(find.text('Solo Order'), findsOneWidget);
    expect(find.text('Start Group Order'), findsOneWidget);
    expect(find.text('Join Session'), findsOneWidget);
  });
}
