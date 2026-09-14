import '../../products/models/product.dart';

class GroupSessionInfo {
  final String id;
  final String code;
  final String status;
  final int version;
  final String hostParticipantId;
  final bool allReady;
  final int totalCartAmount; // in cents
  final DateTime? createdAt;

  const GroupSessionInfo({
    required this.id,
    required this.code,
    required this.status,
    required this.version,
    required this.hostParticipantId,
    required this.allReady,
    required this.totalCartAmount,
    this.createdAt,
  });

  String get formattedTotalAmount =>
      '\$${(totalCartAmount / 100).toStringAsFixed(2)}';

  factory GroupSessionInfo.fromJson(Map<String, dynamic> json) {
    return GroupSessionInfo(
      id: json['id'] as String,
      code: json['code'] as String,
      status: json['status'] as String? ?? 'ACTIVE',
      version: json['version'] as int? ?? 1,
      hostParticipantId: json['hostParticipantId'] as String? ?? '',
      allReady: json['allReady'] as bool? ?? false,
      totalCartAmount: json['totalCartAmount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class GroupParticipant {
  final String id;
  final String displayName;
  final bool isHost;
  final bool isReady;
  final bool isOnline;

  const GroupParticipant({
    required this.id,
    required this.displayName,
    required this.isHost,
    required this.isReady,
    required this.isOnline,
  });

  factory GroupParticipant.fromJson(Map<String, dynamic> json) {
    return GroupParticipant(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? 'Guest',
      isHost: json['isHost'] as bool? ?? false,
      isReady: json['isReady'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }

  GroupParticipant copyWith({
    String? id,
    String? displayName,
    bool? isHost,
    bool? isReady,
    bool? isOnline,
  }) {
    return GroupParticipant(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class GroupCartItem {
  final String id;
  final String productId;
  final String productName;
  final int price; // in cents
  final String imageUrl;
  final int quantity;
  final int lineTotal;
  final String participantId;
  final String addedByName;

  const GroupCartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.lineTotal,
    required this.participantId,
    required this.addedByName,
  });

  String get formattedPrice => '\$${(price / 100).toStringAsFixed(2)}';
  String get formattedLineTotal => '\$${(lineTotal / 100).toStringAsFixed(2)}';

  factory GroupCartItem.fromJson(Map<String, dynamic> json) {
    final price = json['price'] as int? ?? 0;
    final quantity = json['quantity'] as int? ?? 1;
    final lineTotal = json['lineTotal'] as int? ?? (price * quantity);

    return GroupCartItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String? ?? 'Item',
      price: price,
      imageUrl: json['imageUrl'] as String? ?? '',
      quantity: quantity,
      lineTotal: lineTotal,
      participantId: json['participantId'] as String? ?? '',
      addedByName: json['addedByName'] as String? ?? 'Someone',
    );
  }
}

class GroupSessionState {
  final GroupSessionInfo session;
  final List<GroupParticipant> participants;
  final List<GroupCartItem> cartItems;
  final List<Product> products;
  final GroupParticipant currentParticipant;

  const GroupSessionState({
    required this.session,
    required this.participants,
    required this.cartItems,
    required this.products,
    required this.currentParticipant,
  });

  bool get isCurrentParticipantHost => currentParticipant.isHost;

  bool get isCurrentParticipantReady {
    final me = participants.firstWhere(
      (p) => p.id == currentParticipant.id,
      orElse: () => currentParticipant,
    );
    return me.isReady;
  }

  int get readyParticipantCount =>
      participants.where((p) => p.isReady).length;

  int get totalCartItemCount =>
      cartItems.fold(0, (sum, i) => sum + i.quantity);

  String get formattedTotalAmount => session.formattedTotalAmount;

  GroupSessionState copyWith({
    GroupSessionInfo? session,
    List<GroupParticipant>? participants,
    List<GroupCartItem>? cartItems,
    List<Product>? products,
    GroupParticipant? currentParticipant,
  }) {
    return GroupSessionState(
      session: session ?? this.session,
      participants: participants ?? this.participants,
      cartItems: cartItems ?? this.cartItems,
      products: products ?? this.products,
      currentParticipant: currentParticipant ?? this.currentParticipant,
    );
  }
}
