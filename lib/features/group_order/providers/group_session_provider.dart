import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/websocket/ws_client.dart';
import '../../products/models/product.dart';
import '../../products/providers/products_provider.dart';
import '../data/group_repository.dart';
import '../models/group_session.dart';

final wsClientProvider = Provider<WsClient>((ref) {
  final client = WsClient();
  ref.onDispose(() => client.dispose());
  return client;
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

class GroupSessionNotifier extends StateNotifier<GroupSessionState?> {
  final Ref _ref;
  StreamSubscription? _wsSubscription;
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  GroupSessionNotifier(this._ref) : super(null);

  Stream<String> get errorStream => _errorController.stream;
  WsClient get _wsClient => _ref.read(wsClientProvider);

  void initSession({
    required GroupSessionInfo session,
    required GroupParticipant currentParticipant,
    List<GroupParticipant> participants = const [],
    List<GroupCartItem> cartItems = const [],
    List<Product> products = const [],
  }) {
    final defaultProducts = products.isNotEmpty
        ? products
        : (_ref.read(productsProvider).valueOrNull ?? const <Product>[]);

    state = GroupSessionState(
      session: session,
      currentParticipant: currentParticipant,
      participants: participants.isNotEmpty ? participants : [currentParticipant],
      cartItems: cartItems,
      products: defaultProducts,
    );

    // Connect WebSocket
    _connectWebSocket(session.id, currentParticipant.id);
  }

  void _connectWebSocket(String sessionId, String participantId) {
    _wsSubscription?.cancel();
    _wsClient.connect(sessionId: sessionId, participantId: participantId);

    _wsSubscription = _wsClient.eventStream.listen((event) {
      _handleWsEvent(event);
    });
  }

  void _handleWsEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final data = event['data'] as Map<String, dynamic>?;

    if (state == null) return;

    switch (type) {
      case 'SESSION_STATE':
        if (data != null) {
          final sessionJson = data['session'] as Map<String, dynamic>?;
          final participantsJson = data['participants'] as List? ?? [];
          final cartItemsJson = data['cartItems'] as List? ?? [];
          final productsJson = data['products'] as List? ?? [];

          final sessionInfo = sessionJson != null
              ? GroupSessionInfo.fromJson(sessionJson)
              : state!.session;

          final participantsList = participantsJson
              .map((p) => GroupParticipant.fromJson(p as Map<String, dynamic>))
              .toList();

          final cartList = cartItemsJson
              .map((c) => GroupCartItem.fromJson(c as Map<String, dynamic>))
              .toList();

          final productsList = productsJson
              .map((p) => Product.fromJson(p as Map<String, dynamic>))
              .toList();

          state = state!.copyWith(
            session: sessionInfo,
            participants: participantsList,
            cartItems: cartList,
            products: productsList,
          );
        }
        break;

      case 'PARTICIPANT_STATUS_CHANGED':
        if (data != null) {
          final participantsJson = data['participants'] as List?;
          if (participantsJson != null) {
            final updatedParticipants = participantsJson
                .map((p) => GroupParticipant.fromJson(p as Map<String, dynamic>))
                .toList();

            final allReady = data['allReady'] as bool? ?? state!.session.allReady;

            state = state!.copyWith(
              participants: updatedParticipants,
              session: state!.session.copyWith(allReady: allReady),
            );
          }
        }
        break;

      case 'CART_UPDATED':
        if (data != null) {
          final cartItemsJson = data['cartItems'] as List? ?? [];
          final totalCartAmount = data['totalCartAmount'] as int? ?? 0;
          final version = data['version'] as int? ?? state!.session.version;

          final cartList = cartItemsJson
              .map((c) => GroupCartItem.fromJson(c as Map<String, dynamic>))
              .toList();

          state = state!.copyWith(
            cartItems: cartList,
            session: state!.session.copyWith(
              totalCartAmount: totalCartAmount,
              version: version,
            ),
          );
        }
        break;

      case 'INVENTORY_UPDATED':
        if (data != null) {
          final productId = data['productId'] as String?;
          final availableStock = data['availableStock'] as int?;
          final totalStock = data['totalStock'] as int?;
          final isOutOfStock = data['isOutOfStock'] as bool?;
          final isLowStock = data['isLowStock'] as bool?;

          if (productId != null && availableStock != null) {
            _ref.read(productsProvider.notifier).updateProductStock(productId, availableStock);

            final updatedProducts = state!.products.map((p) {
              if (p.id == productId) {
                return p.copyWith(
                  availableStock: availableStock,
                  totalStock: totalStock ?? p.totalStock,
                  isOutOfStock: isOutOfStock,
                  isLowStock: isLowStock,
                );
              }
              return p;
            }).toList();

            state = state!.copyWith(products: updatedProducts);
          }
        }
        break;

      case 'ERROR':
        final msg = event['message'] as String? ?? 'An unexpected error occurred';
        _errorController.add(msg);
        break;

      default:
        break;
    }
  }

  void addToCart(String productId, [int quantity = 1]) {
    if (state == null) return;
    _wsClient.send({
      'type': 'CART_ADD',
      'sessionId': state!.session.id,
      'participantId': state!.currentParticipant.id,
      'productId': productId,
      'quantity': quantity,
    });
  }

  void updateQuantity(String cartItemId, int quantity) {
    if (state == null) return;
    _wsClient.send({
      'type': 'CART_UPDATE',
      'sessionId': state!.session.id,
      'participantId': state!.currentParticipant.id,
      'cartItemId': cartItemId,
      'quantity': quantity,
    });
  }

  void removeItem(String cartItemId) {
    if (state == null) return;
    _wsClient.send({
      'type': 'CART_REMOVE',
      'sessionId': state!.session.id,
      'participantId': state!.currentParticipant.id,
      'cartItemId': cartItemId,
    });
  }

  void leaveSession() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsClient.disconnect();
    state = null;
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _errorController.close();
    super.dispose();
  }
}

final groupSessionProvider =
    StateNotifierProvider<GroupSessionNotifier, GroupSessionState?>((ref) {
  return GroupSessionNotifier(ref);
});
