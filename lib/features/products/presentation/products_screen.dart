import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_theme.dart';
import '../../normal_order/presentation/solo_checkout_sheet.dart';
import '../../normal_order/providers/solo_cart_provider.dart';
import '../providers/products_provider.dart';
import 'widgets/product_card.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _selectedCategory = 'All';

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SoloCheckoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(soloCartProvider);
    final cartNotifier = ref.read(soloCartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: cart.isNotEmpty,
              label: Text('${cart.totalItemCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: cart.isNotEmpty ? _openCartSheet : null,
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load menu:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(productsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (products) {
          final categories = [
            'All',
            ...{for (final p in products) p.category}
          ];

          final filteredProducts = _selectedCategory == 'All'
              ? products
              : products.where((p) => p.category == _selectedCategory).toList();

          return Column(
            children: [
              // Category filter bar
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primaryDark,
                        labelStyle: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Product list with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(productsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final qty = cart.quantityFor(product.id);

                      return ProductCard(
                        product: product,
                        cartQuantity: qty,
                        onAdd: () => cartNotifier.addItem(product),
                        onDecrement: () => cartNotifier.decrementItem(product.id),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // Bottom floating cart bar
      bottomNavigationBar: cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.totalItemCount} items in cart',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          cart.formattedTotalAmount,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 44),
                      ),
                      onPressed: _openCartSheet,
                      icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                      label: const Text('View Cart'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
