import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int cartQuantity;
  final VoidCallback onAdd;
  final VoidCallback onDecrement;

  const ProductCard({
    super.key,
    required this.product,
    required this.cartQuantity,
    required this.onAdd,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOut = product.isOutOfStock;
    final isMaxInCart = cartQuantity >= product.availableStock;

    return Card(
      key: ValueKey('product_${product.id}'),
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 96,
                height: 96,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    child: Icon(
                      Icons.fastfood_outlined,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      size: 36,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Stock Status Tag
                  Row(
                    children: [
                      Text(
                        product.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      _StockBadge(product: product),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Description
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price and Add / Quantity Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),

                      // Actions
                      if (isOut)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Unavailable',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (cartQuantity == 0)
                        ElevatedButton(
                          onPressed: onAdd,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(76, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Add +',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                icon: const Icon(Icons.remove),
                                onPressed: onDecrement,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '$cartQuantity',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                icon: const Icon(Icons.add),
                                onPressed: isMaxInCart ? null : onAdd,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final Product product;

  const _StockBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;

    if (product.isOutOfStock) {
      bg = isDark ? const Color(0xFF451A1A) : Colors.red.shade100;
      fg = isDark ? const Color(0xFFFCA5A5) : Colors.red.shade900;
    } else if (product.isLowStock) {
      bg = isDark ? const Color(0xFF452B1A) : Colors.orange.shade100;
      fg = isDark ? const Color(0xFFFDBA74) : Colors.orange.shade900;
    } else {
      bg = isDark ? const Color(0xFF1A3B2B) : Colors.green.shade100;
      fg = isDark ? const Color(0xFF86EFAC) : Colors.green.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        product.stockStatusLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
