import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/models/product.dart';

class SoloCartItem {
  final Product product;
  final int quantity;

  const SoloCartItem({
    required this.product,
    required this.quantity,
  });

  int get lineTotalCents => product.price * quantity;
  String get formattedLineTotal => '\$${(lineTotalCents / 100).toStringAsFixed(2)}';

  SoloCartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return SoloCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class SoloCartState {
  final Map<String, SoloCartItem> items;

  const SoloCartState({this.items = const {}});

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalItemCount => items.values.fold(0, (sum, i) => sum + i.quantity);

  int get totalAmountCents => items.values.fold(0, (sum, i) => sum + i.lineTotalCents);

  String get formattedTotalAmount => '\$${(totalAmountCents / 100).toStringAsFixed(2)}';

  int quantityFor(String productId) => items[productId]?.quantity ?? 0;

  SoloCartState copyWith({Map<String, SoloCartItem>? items}) {
    return SoloCartState(items: items ?? this.items);
  }
}

class SoloCartNotifier extends StateNotifier<SoloCartState> {
  SoloCartNotifier() : super(const SoloCartState());

  void addItem(Product product) {
    if (product.availableStock <= 0) return;

    final currentItem = state.items[product.id];
    final currentQty = currentItem?.quantity ?? 0;

    // Do not exceed available stock
    if (currentQty >= product.availableStock) return;

    final updated = Map<String, SoloCartItem>.from(state.items);
    updated[product.id] = SoloCartItem(
      product: product,
      quantity: currentQty + 1,
    );

    state = state.copyWith(items: updated);
  }

  void decrementItem(String productId) {
    final currentItem = state.items[productId];
    if (currentItem == null) return;

    final updated = Map<String, SoloCartItem>.from(state.items);
    if (currentItem.quantity <= 1) {
      updated.remove(productId);
    } else {
      updated[productId] = currentItem.copyWith(quantity: currentItem.quantity - 1);
    }

    state = state.copyWith(items: updated);
  }

  void removeItem(String productId) {
    if (!state.items.containsKey(productId)) return;
    final updated = Map<String, SoloCartItem>.from(state.items)..remove(productId);
    state = state.copyWith(items: updated);
  }

  void clear() {
    state = const SoloCartState();
  }
}

final soloCartProvider = StateNotifierProvider<SoloCartNotifier, SoloCartState>((ref) {
  return SoloCartNotifier();
});
