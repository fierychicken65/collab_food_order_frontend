import 'package:flutter_test/flutter_test.dart';
import 'package:collab_food_order_frontend/features/products/models/product.dart';
import 'package:collab_food_order_frontend/features/normal_order/providers/solo_cart_provider.dart';

void main() {
  group('SoloCartNotifier & Product Model Tests', () {
    const testProduct = Product(
      id: 'prod-1',
      name: 'Cheeseburger',
      description: 'Tasty burger',
      price: 999, // $9.99
      imageUrl: 'http://example.com/burger.jpg',
      category: 'Burgers',
      totalStock: 5,
      availableStock: 2, // low stock test
      isOutOfStock: false,
      isLowStock: true,
    );

    test('Product formatting getters work correctly', () {
      expect(testProduct.formattedPrice, '\$9.99');
      expect(testProduct.stockStatusLabel, 'Only 2 left!');
    });

    test('SoloCartNotifier adds, decrements, and respects stock bounds', () {
      final notifier = SoloCartNotifier();

      // Add 1
      notifier.addItem(testProduct);
      expect(notifier.state.totalItemCount, 1);
      expect(notifier.state.totalAmountCents, 999);
      expect(notifier.state.formattedTotalAmount, '\$9.99');

      // Add 2nd (reaches availableStock: 2)
      notifier.addItem(testProduct);
      expect(notifier.state.totalItemCount, 2);
      expect(notifier.state.totalAmountCents, 1998);

      // Attempt to add 3rd (exceeds availableStock: 2) -> should be ignored
      notifier.addItem(testProduct);
      expect(notifier.state.totalItemCount, 2);

      // Decrement
      notifier.decrementItem(testProduct.id);
      expect(notifier.state.totalItemCount, 1);

      // Remove
      notifier.removeItem(testProduct.id);
      expect(notifier.state.isEmpty, true);
    });
  });
}
