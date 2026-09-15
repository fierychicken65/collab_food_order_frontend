import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';

enum WsConnectionStatus { connecting, connected, disconnected }

class WsClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  final _statusController = StreamController<WsConnectionStatus>.broadcast();
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  String? _lastSessionId;
  String? _lastParticipantId;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;

  Stream<WsConnectionStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  WsConnectionStatus _currentStatus = WsConnectionStatus.disconnected;
  WsConnectionStatus get currentStatus => _currentStatus;

  void _setStatus(WsConnectionStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void connect({required String sessionId, required String participantId}) {
    _lastSessionId = sessionId;
    _lastParticipantId = participantId;
    _isDisposed = false;
    _reconnectTimer?.cancel();

    _setStatus(WsConnectionStatus.connecting);

    try {
      final uri = Uri.parse(ApiConstants.wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          debugPrint('[WS] Connection closed');
          _cleanup();
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint('[WS] Error: $error');
          _cleanup();
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      _setStatus(WsConnectionStatus.connected);
      _reconnectAttempts = 0;

      // Join session immediately upon connection
      send({
        'type': 'JOIN_SESSION',
        'sessionId': sessionId,
        'participantId': participantId,
      });

      // Start ping heartbeat
      _startPingHeartbeat();
    } catch (e) {
      debugPrint('[WS] Connect error: $e');
      _cleanup();
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final String text = raw.toString();
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      if (!_eventController.isClosed) {
        _eventController.add(decoded);
      }
    } catch (e) {
      debugPrint('[WS] Failed to parse message: $e');
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null && _currentStatus == WsConnectionStatus.connected) {
      try {
        final payload = jsonEncode(data);
        _channel!.sink.add(payload);
      } catch (e) {
        debugPrint('[WS] Send error: $e');
      }
    } else {
      debugPrint('[WS] Cannot send message, socket not connected');
    }
  }

  void _startPingHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      send({'type': 'PING'});
    });
  }

  void _scheduleReconnect() {
    if (_isDisposed || _lastSessionId == null || _lastParticipantId == null) return;

    _setStatus(WsConnectionStatus.disconnected);

    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 2).clamp(2, 20);
    debugPrint('[WS] Scheduling reconnect attempt $_reconnectAttempts in ${delaySeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed && _lastSessionId != null && _lastParticipantId != null) {
        connect(
          sessionId: _lastSessionId!,
          participantId: _lastParticipantId!,
        );
      }
    });
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
  }

  void reconnect() {
    if (_lastSessionId != null && _lastParticipantId != null) {
      _reconnectTimer?.cancel();
      _cleanup();
      connect(
        sessionId: _lastSessionId!,
        participantId: _lastParticipantId!,
      );
    }
  }

  void requestSync() {
    if (_lastSessionId != null) {
      send({
        'type': 'REQUEST_SYNC',
        'sessionId': _lastSessionId,
      });
    }
  }

  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _cleanup();
    _setStatus(WsConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _eventController.close();
  }
}
