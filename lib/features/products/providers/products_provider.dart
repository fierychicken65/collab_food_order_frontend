import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../data/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final repository = ref.read(productRepositoryProvider);
    return repository.fetchProducts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(productRepositoryProvider).fetchProducts());
  }

  void updateProductStock(String productId, int newAvailableStock) {
    state = state.whenData((products) {
      return products.map((p) {
        if (p.id == productId) {
          return p.copyWith(availableStock: newAvailableStock);
        }
        return p;
      }).toList();
    });
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(() {
  return ProductsNotifier();
});
