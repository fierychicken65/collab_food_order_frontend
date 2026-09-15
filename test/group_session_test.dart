import 'package:flutter_test/flutter_test.dart';
import 'package:collab_food_order_frontend/features/group_order/models/group_session.dart';

void main() {
  group('GroupSession Models & State Tests', () {
    test('GroupSessionInfo parses JSON correctly', () {
      final json = {
        'id': 'sess-123',
        'code': 'PIZZA1',
        'status': 'ACTIVE',
        'version': 3,
        'hostParticipantId': 'user-host',
        'allReady': false,
        'totalCartAmount': 2499,
        'createdAt': '2026-09-14T10:00:00.000Z',
      };

      final info = GroupSessionInfo.fromJson(json);
      expect(info.id, 'sess-123');
      expect(info.code, 'PIZZA1');
      expect(info.version, 3);
      expect(info.formattedTotalAmount, '\$24.99');
      expect(info.allReady, false);
    });

    test('GroupSessionState correctly computes readiness and host identity', () {
      const host = GroupParticipant(
        id: 'user-host',
        displayName: 'Host Alice',
        isHost: true,
        isReady: true,
        isOnline: true,
      );

      const guest = GroupParticipant(
        id: 'user-guest',
        displayName: 'Guest Bob',
        isHost: false,
        isReady: false,
        isOnline: true,
      );

      const session = GroupSessionInfo(
        id: 'sess-123',
        code: 'PIZZA1',
        status: 'ACTIVE',
        version: 1,
        hostParticipantId: 'user-host',
        allReady: false,
        totalCartAmount: 0,
      );

      final state = GroupSessionState(
        session: session,
        participants: [host, guest],
        cartItems: const [],
        products: const [],
        currentParticipant: host,
      );

      expect(state.isCurrentParticipantHost, true);
      expect(state.isCurrentParticipantReady, true);
      expect(state.readyParticipantCount, 1);
    });

    test('GroupSessionInfo parses CLOSED status correctly', () {
      final json = {
        'id': 'sess-closed',
        'code': 'BURGER',
        'status': 'CLOSED',
        'version': 5,
        'hostParticipantId': 'user-host',
        'allReady': false,
        'totalCartAmount': 0,
      };

      final info = GroupSessionInfo.fromJson(json);
      expect(info.status, 'CLOSED');
    });
  });
}
