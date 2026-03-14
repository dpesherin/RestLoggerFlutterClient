import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/message.dart';
import '../utils/config.dart';
import '../utils/error_handler.dart';
import 'storage_service.dart';

typedef MessageCallback = void Function(Message message);
typedef ConnectionCallback = void Function(bool connected);
typedef StatusCallback = void Function(ConnectionStatus status);

class ConnectionStatus {
  final bool isConnected;
  final bool isReconnecting;
  final int reconnectAttempts;
  final int maxReconnectAttempts;
  final int totalReconnects;
  final int? latencyMs;
  final String? lastError;

  const ConnectionStatus({
    required this.isConnected,
    required this.isReconnecting,
    required this.reconnectAttempts,
    required this.maxReconnectAttempts,
    required this.totalReconnects,
    this.latencyMs,
    this.lastError,
  });
}

class WebSocketService {
  io.Socket? _socket;
  late MessageCallback _onMessage;
  ConnectionCallback? _onConnectionChange;
  StatusCallback? _onStatusChange;

  Timer? _reconnectTimer;
  Stopwatch? _connectStopwatch;

  bool _manualDisconnect = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  int _totalReconnects = 0;
  int? _latencyMs;
  String? _lastError;

  static const int maxReconnectAttempts = 5;

  bool get isConnected => _socket?.connected ?? false;

  ConnectionStatus get status => ConnectionStatus(
        isConnected: isConnected,
        isReconnecting: _isReconnecting,
        reconnectAttempts: _reconnectAttempts,
        maxReconnectAttempts: maxReconnectAttempts,
        totalReconnects: _totalReconnects,
        latencyMs: _latencyMs,
        lastError: _lastError,
      );

  Future<void> connect({
    required MessageCallback onMessage,
    ConnectionCallback? onConnectionChange,
    StatusCallback? onStatusChange,
  }) async {
    return suppressErrorsAsync(() async {
      _onMessage = onMessage;
      _onConnectionChange = onConnectionChange;
      _onStatusChange = onStatusChange;
      _manualDisconnect = false;

      if (_socket != null) {
        _emitStatus();
        return;
      }

      await _openSocket(resetReconnectAttempts: false);
    });
  }

  void disconnect() {
    suppressErrors(() {
      _manualDisconnect = true;
      _isReconnecting = false;
      _reconnectTimer?.cancel();
      _cleanupSocket();
      _onConnectionChange?.call(false);
      _emitStatus();
    });
  }

  void reconnect() {
    suppressErrors(() {
      _manualDisconnect = false;
      _reconnectTimer?.cancel();
      _cleanupSocket();
      _reconnectAttempts = 0;
      _lastError = null;
      _isReconnecting = true;
      _emitStatus();

      Future<void>.delayed(const Duration(milliseconds: 300), () {
        _openSocket(resetReconnectAttempts: true);
      });
    });
  }

  Future<void> _openSocket({required bool resetReconnectAttempts}) async {
    if (resetReconnectAttempts) {
      _reconnectAttempts = 0;
    }

    final token = await StorageService.getToken();
    _connectStopwatch = Stopwatch()..start();

    _socket = suppressErrors(() {
      final Map<String, dynamic> opts = {
        'path': '/socket.io',
        'transports': ['websocket', 'polling'],
        'withCredentials': true,
        'reconnection': false,
        'timeout': 10000,
        'autoConnect': false,
        'forceNew': true,
      };

      if (token != null && token.isNotEmpty) {
        opts['extraHeaders'] = {
          'Cookie': 'token=$token',
          'Origin': AppConfig.wsUrl,
        };
        opts['query'] = {'token': token};
      }

      return io.io(AppConfig.wsUrl, opts);
    });

    if (_socket == null) {
      _scheduleReconnect('Не удалось создать WebSocket');
      return;
    }

    _socket!.on('connect', (_) {
      suppressErrors(() {
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        _isReconnecting = false;
        _reconnectAttempts = 0;
        _lastError = null;
        _latencyMs = _connectStopwatch?.elapsedMilliseconds;
        _connectStopwatch?.stop();

        _socket!.once('consumer', (key) {
          if (key != null) {
            StorageService.saveConsumerKey(key.toString());
          }
          _onConnectionChange?.call(true);
          _emitStatus();
        });

        _emitStatus();
      });
    });

    _socket!.on('pushMess', (data) {
      suppressErrors(() {
        _handleIncomingMessage(data);
      });
    });

    _socket!.on('pong', (data) {
      suppressErrors(() {
        if (data is num) {
          _latencyMs = data.round();
          _emitStatus();
        }
      });
    });

    _socket!.on('error', (error) {
      suppressErrors(() {
        _lastError = error?.toString();
        _emitStatus();
      });
    });

    _socket!.on('disconnect', (_) {
      suppressErrors(() {
        _onConnectionChange?.call(false);
        if (_manualDisconnect) {
          _emitStatus();
          return;
        }
        _scheduleReconnect('Соединение разорвано');
      });
    });

    _socket!.on('connect_error', (error) {
      suppressErrors(() {
        _lastError = error?.toString() ?? 'Ошибка подключения';
        _onConnectionChange?.call(false);
        _scheduleReconnect(_lastError);
      });
    });

    _socket!.connect();
    _emitStatus();
  }

  void _scheduleReconnect(String? error) {
    if (_manualDisconnect) return;
    if (_reconnectTimer?.isActive ?? false) return;

    _cleanupSocket();
    _lastError = error;

    if (_reconnectAttempts >= maxReconnectAttempts) {
      _isReconnecting = false;
      _emitStatus();
      return;
    }

    _reconnectAttempts++;
    _totalReconnects++;
    _isReconnecting = true;
    _emitStatus();

    final delay = Duration(seconds: _reconnectAttempts.clamp(1, 3));
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _openSocket(resetReconnectAttempts: false);
    });
  }

  void _cleanupSocket() {
    _connectStopwatch?.stop();
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
  }

  void _handleIncomingMessage(dynamic data) {
    suppressErrors(() {
      Map<String, dynamic> messageData;

      if (data is Map) {
        messageData = Map<String, dynamic>.from(data);
      } else {
        messageData = {'msg': data.toString(), 'mode': 'light'};
      }

      if (!messageData.containsKey('timestamp')) {
        messageData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }

      final message = Message.fromJson(messageData);
      _onMessage(message);
    });
  }

  void _emitStatus() {
    _onStatusChange?.call(status);
  }
}
