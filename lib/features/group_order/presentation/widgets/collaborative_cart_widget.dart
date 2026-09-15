import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../models/group_session.dart';

class CollaborativeCartWidget extends StatelessWidget {
  final List<GroupCartItem> cartItems;
  final String currentParticipantId;
  final int totalCartAmount;
  final bool isHost;
  final bool isReady;
  final bool allReady;
  final int readyCount;
  final int totalParticipants;
  final VoidCallback onToggleReady;
  final VoidCallback onPlaceOrder;
  final Function(String cartItemId, int newQuantity) onUpdateQuantity;
  final Function(String cartItemId) onRemoveItem;

  const CollaborativeCartWidget({
    super.key,
    required this.cartItems,
    required this.currentParticipantId,
    required this.totalCartAmount,
    required this.isHost,
    required this.isReady,
    required this.allReady,
    required this.readyCount,
    required this.totalParticipants,
    required this.onToggleReady,
    required this.onPlaceOrder,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
  });

  String get formattedTotal =>
      '\$${(totalCartAmount / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Personal Readiness Status Card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isReady ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isReady ? Colors.green.shade200 : Colors.orange.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isReady
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isReady ? Colors.green.shade700 : Colors.orange.shade800,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReady
                          ? "You are marked as Ready"
                          : "You are Still Browsing",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isReady
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isReady
                          ? 'Waiting for remaining group members'
                          : 'Mark yourself ready when done picking food',
                      style: TextStyle(
                        fontSize: 11,
                        color: isReady
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                key: const ValueKey('toggle_ready_button'),
                onPressed: onToggleReady,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: isReady
                      ? Colors.green.shade900
                      : Colors.orange.shade900,
                  side: BorderSide(
                    color: isReady
                        ? Colors.green.shade400
                        : Colors.orange.shade400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isReady ? 'Still Browsing' : "I'm Ready!",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Cart Items List or Empty State
        Expanded(
          child: cartItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shopping_basket_outlined,
                            size: 36,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Group Cart is Empty',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Browse the Menu tab and add food items! Group additions show up in real-time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: cartItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final isMe = item.participantId == currentParticipantId;

                    return Container(
                      key: ValueKey('cart_item_${item.id}'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMe
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.grey.shade200,
                          width: isMe ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Food thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(
                                      item.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.fastfood_outlined,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.fastfood_outlined,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Product details & attribution
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // Price per unit
                                Text(
                                  '${item.formattedPrice} each',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Explicit Item Attribution Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.primaryLight
                                            .withValues(alpha: 0.35)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isMe
                                            ? Icons.person_rounded
                                            : Icons.person_outline_rounded,
                                        size: 13,
                                        color: isMe
                                            ? AppColors.primaryDark
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          isMe
                                              ? 'Added by ${item.addedByName} (You)'
                                              : 'Added by ${item.addedByName}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isMe
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isMe
                                                ? AppColors.primaryDark
                                                : AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Stepper & line total
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item.formattedLineTotal,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Quantity controls
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      iconSize: 16,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      icon: Icon(
                                        item.quantity <= 1
                                            ? Icons.delete_outline
                                            : Icons.remove,
                                        color: item.quantity <= 1
                                            ? Colors.red.shade600
                                            : AppColors.textPrimary,
                                      ),
                                      onPressed: () {
                                        if (item.quantity <= 1) {
                                          onRemoveItem(item.id);
                                        } else {
                                          onUpdateQuantity(
                                            item.id,
                                            item.quantity - 1,
                                          );
                                        }
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      iconSize: 16,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      icon: const Icon(Icons.add),
                                      onPressed: () => onUpdateQuantity(
                                        item.id,
                                        item.quantity + 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Bottom Action Bar with Total & Host Checkout
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total and Live Synced pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Cart Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedTotal,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live Synced',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Host Checkout Button vs Participant Waiting Banner
                if (isHost) ...[
                  ElevatedButton(
                    key: const ValueKey('host_checkout_button'),
                    onPressed: (cartItems.isNotEmpty && allReady)
                        ? onPlaceOrder
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('Place Group Order ($formattedTotal)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      cartItems.isEmpty
                          ? 'Add items to cart before placing order'
                          : !allReady
                              ? 'Waiting for all members to be ready ($readyCount/$totalParticipants Ready)'
                              : 'All participants ready! You can now place the order.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (!allReady || cartItems.isEmpty)
                            ? Colors.orange.shade800
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: allReady
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: allReady
                            ? Colors.green.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          allReady
                              ? Icons.hourglass_top_rounded
                              : Icons.group_outlined,
                          size: 18,
                          color: allReady
                              ? Colors.green.shade800
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            allReady
                                ? 'All members ready! Waiting for Host to place order...'
                                : 'Waiting for members: $readyCount of $totalParticipants ready',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: allReady
                                  ? Colors.green.shade900
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
