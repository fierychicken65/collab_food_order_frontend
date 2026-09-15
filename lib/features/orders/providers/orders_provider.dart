import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OrderType { solo, group }

class OrderRecordItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? addedByName;

  const OrderRecordItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.addedByName,
  });

  double get lineTotal => quantity * unitPrice;
  String get formattedLineTotal => '\$${lineTotal.toStringAsFixed(2)}';
}

class OrderRecord {
  final String id;
  final DateTime timestamp;
  final OrderType type;
  final String customerName;
  final String? sessionCode;
  final List<OrderRecordItem> items;
  final double totalAmount;
  final String status;

  const OrderRecord({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.customerName,
    this.sessionCode,
    required this.items,
    required this.totalAmount,
    required this.status,
  });

  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';
}

class OrdersNotifier extends StateNotifier<List<OrderRecord>> {
  OrdersNotifier() : super([]);

  void addOrder(OrderRecord order) {
    state = [order, ...state];
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderRecord>>((ref) {
  return OrdersNotifier();
});
