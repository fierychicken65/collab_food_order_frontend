import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../products/providers/products_provider.dart';
import '../providers/solo_cart_provider.dart';

import '../../orders/providers/orders_provider.dart';
import '../../user/providers/user_provider.dart';

class SoloCheckoutSheet extends ConsumerStatefulWidget {
  const SoloCheckoutSheet({super.key});

  @override
  ConsumerState<SoloCheckoutSheet> createState() => _SoloCheckoutSheetState();
}

class _SoloCheckoutSheetState extends ConsumerState<SoloCheckoutSheet> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final savedName = ref.read(userProvider).name;
    _nameController = TextEditingController(
      text: savedName.isNotEmpty ? savedName : 'Customer',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = ref.read(soloCartProvider);
    if (cart.isEmpty) return;

    final customerName = _nameController.text.trim();
    ref.read(userProvider.notifier).updateName(customerName);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final client = ApiClient();
      final itemsPayload = cart.items.values
          .map((item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
              })
          .toList();

      final response = await client.post(
        ApiConstants.soloOrder,
        body: {
          'customerName': customerName,
          'items': itemsPayload,
        },
      );

      final orderData = response['order'] as Map<String, dynamic>?;

      // Record order into local orders history
      final recordItems = cart.items.values
          .map((item) => OrderRecordItem(
                productName: item.product.name,
                quantity: item.quantity,
                unitPrice: item.product.price / 100.0,
              ))
          .toList();

      ref.read(ordersProvider.notifier).addOrder(OrderRecord(
            id: (orderData?['id'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            type: OrderType.solo,
            customerName: customerName,
            items: recordItems,
            totalAmount: (cart.totalAmountCents) / 100.0,
            status: 'CONFIRMED',
          ));

      // Clear cart
      ref.read(soloCartProvider.notifier).clear();
      // Refresh catalog stock
      ref.read(productsProvider.notifier).refresh();

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss sheet

      _showSuccessDialog(orderData);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  void _showSuccessDialog(Map<String, dynamic>? order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Confirmed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you, ${order?['customerName'] ?? 'Customer'}!\nYour solo order has been received.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Paid:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '\$${(((order?['totalAmount'] as int? ?? 0)) / 100).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Back to home
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(soloCartProvider);
    final cartNotifier = ref.read(soloCartProvider.notifier);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Cart',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),

              if (cart.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('Your cart is empty', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else ...[
                // Cart Items List
                ...cart.items.values.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${item.formattedLineTotal} (${item.product.formattedPrice} each)',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => cartNotifier.decrementItem(item.product.id),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: item.quantity >= item.product.availableStock
                                  ? null
                                  : () => cartNotifier.addItem(item.product),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(height: 24),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                    ),
                  ),

                // Total Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(
                      cart.formattedTotalAmount,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Checkout Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleCheckout,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text('Confirm & Place Order (${cart.totalItemCount} items)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
