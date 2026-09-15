import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:collab_food_order_frontend/features/group_order/models/group_session.dart';
import 'package:collab_food_order_frontend/features/group_order/presentation/widgets/collaborative_cart_widget.dart';

void main() {
  group('Collaborative Cart & Item Attribution Tests', () {
    test('GroupCartItem parses JSON and formats price correctly', () {
      final json = {
        'id': 'ci-1',
        'productId': 'prod-1',
        'productName': 'Artisan Truffle Burger',
        'price': 1499,
        'imageUrl': '',
        'quantity': 2,
        'lineTotal': 2998,
        'participantId': 'user-1',
        'addedByName': 'Alice',
      };

      final item = GroupCartItem.fromJson(json);
      expect(item.id, 'ci-1');
      expect(item.productName, 'Artisan Truffle Burger');
      expect(item.price, 1499);
      expect(item.quantity, 2);
      expect(item.lineTotal, 2998);
      expect(item.formattedPrice, '\$14.99');
      expect(item.formattedLineTotal, '\$29.98');
      expect(item.addedByName, 'Alice');
      expect(item.participantId, 'user-1');
    });

    testWidgets('Displays empty state when cart is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollaborativeCartWidget(
              cartItems: const [],
              currentParticipantId: 'user-1',
              totalCartAmount: 0,
              onUpdateQuantity: (_, _) {},
              onRemoveItem: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Group Cart is Empty'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
    });

    testWidgets('Displays item attribution and allows quantity mutations',
        (tester) async {
      String? updatedCartItemId;
      int? updatedQuantity;
      String? removedCartItemId;

      const myItem = GroupCartItem(
        id: 'ci-1',
        productId: 'prod-1',
        productName: 'Classic Smash Cheeseburger',
        price: 999,
        imageUrl: '',
        quantity: 2,
        lineTotal: 1998,
        participantId: 'user-1',
        addedByName: 'Alice',
      );

      const friendItem = GroupCartItem(
        id: 'ci-2',
        productId: 'prod-2',
        productName: 'Loaded Fries',
        price: 649,
        imageUrl: '',
        quantity: 1,
        lineTotal: 649,
        participantId: 'user-2',
        addedByName: 'Bob',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollaborativeCartWidget(
              cartItems: const [myItem, friendItem],
              currentParticipantId: 'user-1',
              totalCartAmount: 2647,
              onUpdateQuantity: (id, qty) {
                updatedCartItemId = id;
                updatedQuantity = qty;
              },
              onRemoveItem: (id) {
                removedCartItemId = id;
              },
            ),
          ),
        ),
      );

      // Verify product names rendered
      expect(find.text('Classic Smash Cheeseburger'), findsOneWidget);
      expect(find.text('Loaded Fries'), findsOneWidget);

      // Verify Item Attribution badges
      expect(find.text('Added by Alice (You)'), findsOneWidget);
      expect(find.text('Added by Bob'), findsOneWidget);

      // Verify Total Cart Amount rendered
      expect(find.text('\$26.47'), findsOneWidget);
      expect(find.text('Live Synced'), findsOneWidget);

      // Tap '+' on myItem (first '+' icon)
      final addIcons = find.byIcon(Icons.add);
      expect(addIcons, findsNWidgets(2));
      await tester.tap(addIcons.first);
      await tester.pump();

      expect(updatedCartItemId, 'ci-1');
      expect(updatedQuantity, 3);

      // Friend item has quantity 1, so its minus button should be delete icon
      final deleteIcon = find.byIcon(Icons.delete_outline);
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pump();

      expect(removedCartItemId, 'ci-2');
    });
  });
}
