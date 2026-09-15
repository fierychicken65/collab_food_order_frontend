import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:collab_food_order_frontend/features/group_order/models/group_session.dart';
import 'package:collab_food_order_frontend/features/group_order/presentation/dialogs/group_order_receipt_dialog.dart';
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
              isHost: true,
              isReady: false,
              allReady: false,
              readyCount: 0,
              totalParticipants: 2,
              onToggleReady: () {},
              onPlaceOrder: () {},
              onUpdateQuantity: (_, _) {},
              onRemoveItem: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Group Cart is Empty'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
      expect(find.text("You are Still Browsing"), findsOneWidget);
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
              isHost: false,
              isReady: true,
              allReady: false,
              readyCount: 1,
              totalParticipants: 2,
              onToggleReady: () {},
              onPlaceOrder: () {},
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

    testWidgets(
        'Host checkout button is disabled until all ready, enabled when all ready',
        (tester) async {
      bool orderPlacedCalled = false;
      bool readyToggled = false;

      const item = GroupCartItem(
        id: 'ci-1',
        productId: 'prod-1',
        productName: 'Burger',
        price: 1000,
        imageUrl: '',
        quantity: 1,
        lineTotal: 1000,
        participantId: 'user-1',
        addedByName: 'Host Alice',
      );

      // 1. When allReady is false -> Checkout button is disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollaborativeCartWidget(
              cartItems: const [item],
              currentParticipantId: 'user-1',
              totalCartAmount: 1000,
              isHost: true,
              isReady: false,
              allReady: false,
              readyCount: 0,
              totalParticipants: 2,
              onToggleReady: () {
                readyToggled = true;
              },
              onPlaceOrder: () {
                orderPlacedCalled = true;
              },
              onUpdateQuantity: (_, _) {},
              onRemoveItem: (_) {},
            ),
          ),
        ),
      );

      // Find checkout button
      final checkoutButton =
          tester.widget<ElevatedButton>(find.byKey(const ValueKey('host_checkout_button')));
      expect(checkoutButton.onPressed, isNull); // Disabled!

      // Toggle ready button
      await tester.tap(find.byKey(const ValueKey('toggle_ready_button')));
      expect(readyToggled, true);

      // 2. When allReady is true -> Checkout button is enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollaborativeCartWidget(
              cartItems: const [item],
              currentParticipantId: 'user-1',
              totalCartAmount: 1000,
              isHost: true,
              isReady: true,
              allReady: true,
              readyCount: 2,
              totalParticipants: 2,
              onToggleReady: () {},
              onPlaceOrder: () {
                orderPlacedCalled = true;
              },
              onUpdateQuantity: (_, _) {},
              onRemoveItem: (_) {},
            ),
          ),
        ),
      );

      final enabledCheckoutButton =
          tester.widget<ElevatedButton>(find.byKey(const ValueKey('host_checkout_button')));
      expect(enabledCheckoutButton.onPressed, isNotNull); // Enabled!

      await tester.tap(find.byKey(const ValueKey('host_checkout_button')));
      await tester.pump();
      expect(orderPlacedCalled, true);
    });

    testWidgets('GroupOrderReceiptDialog displays confirmed order with attribution',
        (tester) async {
      bool homeReturned = false;

      final summary = GroupOrderSummary(
        orderId: 'order-12345678-abcd',
        sessionId: 'sess-1',
        sessionCode: 'BURGER',
        hostDisplayName: 'Host Alice',
        totalAmount: 2500,
        status: 'CONFIRMED',
        createdAt: DateTime.now(),
        items: const [
          GroupOrderItemSummary(
            id: 'oi-1',
            productName: 'Truffle Burger',
            price: 1500,
            quantity: 1,
            lineTotal: 1500,
            addedByName: 'Host Alice',
          ),
          GroupOrderItemSummary(
            id: 'oi-2',
            productName: 'Loaded Fries',
            price: 1000,
            quantity: 1,
            lineTotal: 1000,
            addedByName: 'Bob',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupOrderReceiptDialog(
              order: summary,
              onReturnHome: () {
                homeReturned = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Group Order Confirmed!'), findsOneWidget);
      expect(find.text('Session BURGER • Host: Host Alice'), findsOneWidget);
      expect(find.text('Added by Host Alice'), findsOneWidget);
      expect(find.text('Added by Bob'), findsOneWidget);
      expect(find.text('\$25.00'), findsOneWidget);

      await tester.tap(find.text('Return to Home'));
      expect(homeReturned, true);
    });
  });
}
