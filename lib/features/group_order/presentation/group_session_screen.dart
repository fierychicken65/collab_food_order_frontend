import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/websocket/ws_client.dart';
import '../../products/models/product.dart';
import '../../products/presentation/widgets/product_card.dart';
import '../../products/providers/products_provider.dart';
import '../models/group_session.dart';
import '../providers/group_session_provider.dart';
import 'dialogs/group_order_receipt_dialog.dart';
import 'widgets/collaborative_cart_widget.dart';
import 'widgets/participants_list_widget.dart';

class GroupSessionScreen extends ConsumerStatefulWidget {
  const GroupSessionScreen({super.key});

  @override
  ConsumerState<GroupSessionScreen> createState() => _GroupSessionScreenState();
}

class _GroupSessionScreenState extends ConsumerState<GroupSessionScreen> {
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<GroupOrderSummary>? _orderPlacedSubscription;
  StreamSubscription<String>? _sessionClosedSubscription;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Listen to WS error events and surface them as SnackBars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _errorSubscription =
          ref.read(groupSessionProvider.notifier).errorStream.listen((msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(msg)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      });

      // Listen to ORDER_PLACED broadcast events and display receipt dialog
      _orderPlacedSubscription = ref
          .read(groupSessionProvider.notifier)
          .orderPlacedStream
          .listen((orderSummary) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => GroupOrderReceiptDialog(
            order: orderSummary,
            onReturnHome: () {
              ref.read(groupSessionProvider.notifier).leaveSession();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        );
      });

      // Listen to SESSION_CLOSED broadcast events
      _sessionClosedSubscription = ref
          .read(groupSessionProvider.notifier)
          .sessionClosedStream
          .listen((reason) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Group Session Closed'),
            content: Text(reason),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    _orderPlacedSubscription?.cancel();
    _sessionClosedSubscription?.cancel();
    super.dispose();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Join code "$code" copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmLeaveSession() {
    final isHost = ref.read(groupSessionProvider)?.isCurrentParticipantHost ?? false;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHost ? 'Close Group Session?' : 'Leave Group Session?'),
        content: Text(
          isHost
              ? 'As the host, leaving will close this group session for all participants and release unpurchased cart items.'
              : 'Are you sure you want to disconnect from this shared session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              ref.read(groupSessionProvider.notifier).leaveSession();
              Navigator.of(ctx).pop(); // dismiss dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // back to home
            },
            child: Text(
              isHost ? 'Close Session' : 'Leave',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  GroupCartItem? _findMyCartItem(
    List<GroupCartItem> items,
    String productId,
    String participantId,
  ) {
    for (final item in items) {
      if (item.productId == productId && item.participantId == participantId) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupSessionProvider);
    final wsClient = ref.read(wsClientProvider);

    if (groupState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Order')),
        body: const Center(
          child: Text('No active group session'),
        ),
      );
    }

    final session = groupState.session;
    final currentParticipant = groupState.currentParticipant;

    // Available products: prioritize state.products from WS, fallback to productsProvider
    final allProducts = groupState.products.isNotEmpty
        ? groupState.products
        : (ref.watch(productsProvider).valueOrNull ?? const <Product>[]);

    final categories = [
      'All',
      ...{for (final p in allProducts) p.category},
    ];

    final filteredProducts = _selectedCategory == 'All'
        ? allProducts
        : allProducts.where((p) => p.category == _selectedCategory).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmLeaveSession();
        }
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Group Order'),
                const SizedBox(width: 8),
                // Tap-to-copy join code chip
                InkWell(
                  onTap: () => _copyCode(session.code),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tag,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          session.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _confirmLeaveSession,
            ),
            actions: [
              // Live WebSocket Connection Status Pill
              StreamBuilder<WsConnectionStatus>(
                stream: wsClient.statusStream,
                initialData: wsClient.currentStatus,
                builder: (context, snapshot) {
                  final status =
                      snapshot.data ?? WsConnectionStatus.disconnected;
                  Color dotColor;
                  String statusText;

                  switch (status) {
                    case WsConnectionStatus.connected:
                      dotColor = Colors.green;
                      statusText = 'Live';
                      break;
                    case WsConnectionStatus.connecting:
                      dotColor = Colors.orange;
                      statusText = 'Syncing...';
                      break;
                    case WsConnectionStatus.disconnected:
                      dotColor = Colors.red;
                      statusText = 'Offline';
                      break;
                  }

                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: dotColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: dotColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              tabs: [
                const Tab(
                  icon: Icon(Icons.restaurant_menu_rounded),
                  text: 'Menu',
                ),
                Tab(
                  icon: Badge(
                    label: Text('${groupState.totalCartItemCount}'),
                    isLabelVisible: groupState.totalCartItemCount > 0,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  text: 'Group Cart',
                ),
                Tab(
                  icon: Badge(
                    label: Text('${groupState.participants.length}'),
                    isLabelVisible: groupState.participants.isNotEmpty,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.people_outline_rounded),
                  ),
                  text: 'Participants',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Offline / Reconnection Banner
              StreamBuilder<WsConnectionStatus>(
                stream: wsClient.statusStream,
                initialData: wsClient.currentStatus,
                builder: (context, snapshot) {
                  final status =
                      snapshot.data ?? WsConnectionStatus.disconnected;
                  if (status == WsConnectionStatus.connected) {
                    return const SizedBox.shrink();
                  }

                  final isConnecting =
                      status == WsConnectionStatus.connecting;

                  return Container(
                    width: double.infinity,
                    color: isConnecting
                        ? Colors.amber.shade800
                        : Colors.red.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isConnecting
                              ? Icons.sync_rounded
                              : Icons.cloud_off_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isConnecting
                                ? 'Reconnecting & synchronizing shared session...'
                                : 'Connection lost. Live updates paused.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!isConnecting)
                          TextButton(
                            key: const ValueKey('retry_connection_button'),
                            onPressed: () {
                              ref
                                  .read(groupSessionProvider.notifier)
                                  .retryConnection();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text(
                              'RETRY NOW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // Main Tab Content
              Expanded(
                child: TabBarView(
                  children: [
              // TAB 1: Real-time Menu Catalog
              Column(
                children: [
                  // Category Filter Chips
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = cat == _selectedCategory;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                          backgroundColor: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Products List with Real-time Stock Badges
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final myCartItem = _findMyCartItem(
                                groupState.cartItems,
                                product.id,
                                currentParticipant.id,
                              );

                              return ProductCard(
                                product: product,
                                cartQuantity: myCartItem?.quantity ?? 0,
                                onAdd: () {
                                  ref
                                      .read(groupSessionProvider.notifier)
                                      .addToCart(product.id, 1);
                                },
                                onDecrement: () {
                                  if (myCartItem != null) {
                                    ref
                                        .read(groupSessionProvider.notifier)
                                        .updateQuantity(
                                          myCartItem.id,
                                          myCartItem.quantity - 1,
                                        );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),

              // TAB 2: Live Collaborative Cart with Attribution & Host Checkout
              CollaborativeCartWidget(
                cartItems: groupState.cartItems,
                currentParticipantId: currentParticipant.id,
                totalCartAmount: session.totalCartAmount,
                isHost: groupState.isCurrentParticipantHost,
                isReady: groupState.isCurrentParticipantReady,
                allReady: session.allReady,
                readyCount: groupState.readyParticipantCount,
                totalParticipants: groupState.participants.length,
                onToggleReady: () {
                  ref.read(groupSessionProvider.notifier).toggleReady();
                },
                onPlaceOrder: () {
                  ref.read(groupSessionProvider.notifier).placeGroupOrder();
                },
                onUpdateQuantity: (cartItemId, newQty) {
                  ref
                      .read(groupSessionProvider.notifier)
                      .updateQuantity(cartItemId, newQty);
                },
                onRemoveItem: (cartItemId) {
                  ref
                      .read(groupSessionProvider.notifier)
                      .removeItem(cartItemId);
                },
              ),

              // TAB 3: Members & Session Info
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Join Code Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF263238), Color(0xFF37474F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SHARE JOIN CODE WITH FRIENDS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                session.code,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  color: Colors.white70,
                                ),
                                tooltip: 'Copy Code',
                                onPressed: () => _copyCode(session.code),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Friends enter this code in "Join Group Session" to hop in!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Live Participants List
                    ParticipantsListWidget(
                      participants: groupState.participants,
                      currentParticipantId: currentParticipant.id,
                    ),
                    const SizedBox(height: 24),

                    // Readiness / Role Status Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${groupState.readyParticipantCount} of ${groupState.participants.length} Ready',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentParticipant.isHost
                                      ? 'As Host, you can checkout once everyone is marked as Ready.'
                                      : 'Add items to the shared cart and mark yourself Ready when done.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
);
  }
}
