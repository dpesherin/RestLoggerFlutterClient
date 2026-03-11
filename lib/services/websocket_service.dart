import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import 'storage_service.dart';
import '../utils/error_handler.dart';
import '../utils/config.dart';

typedef MessageCallback = void Function(Message message);
typedef ConnectionCallback = void Function(bool connected);

class WebSocketService {
  IO.Socket? _socket;
  late MessageCallback _onMessage;
  ConnectionCallback? _onConnectionChange;

  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  String? _consumerKey;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({
    required MessageCallback onMessage,
    ConnectionCallback? onConnectionChange,
  }) async {
    return suppressErrorsAsync(() async {
      _onMessage = onMessage;
      _onConnectionChange = onConnectionChange;

      if (_socket != null) return;

      final token = await StorageService.getToken();

      _socket = suppressErrors(() {
        final Map<String, dynamic> opts = {
          'path': '/socket.io',
          'transports': ['websocket', 'polling'],
          'withCredentials': true,
          'reconnection': true,
          'reconnectionAttempts': maxReconnectAttempts,
          'reconnectionDelay': 1000,
          'timeout': 10000,
          'autoConnect': true,
          'forceNew': true,
        };

        if (token != null && token.isNotEmpty) {
          opts['extraHeaders'] = {
            'Cookie': 'token=$token',
            'Origin': AppConfig.wsUrl,
          };
          opts['query'] = {'token': token};
        }

        return IO.io(AppConfig.wsUrl, opts);
      });

      if (_socket == null) return;

      _socket!.on('connect', (_) {
        suppressErrors(() {
          _reconnectAttempts = 0;

          _socket!.once('consumer', (key) {
            if (key != null) {
              _consumerKey = key.toString();
              StorageService.saveConsumerKey(key.toString());
              _onConnectionChange?.call(true);
            }
          });
        });
      });

      _socket!.on('pushMess', (data) {
        suppressErrors(() {
          _handleIncomingMessage(data);
        });
      });

      _socket!.on('error', (error) {
        suppressErrors(() {});
      });

      _socket!.on('disconnect', (_) {
        suppressErrors(() {
          _onConnectionChange?.call(false);
        });
      });

      _socket!.on('connect_error', (error) {
        suppressErrors(() {
          _reconnectAttempts++;
        });
      });

      _socket!.connect();
    });
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

  void disconnect() {
    suppressErrors(() {
      _socket?.disconnect();
      _socket?.close();
      _socket = null;
    });
  }

  void reconnect() {
    suppressErrors(() {
      disconnect();
      Future.delayed(const Duration(seconds: 1), () {
        connect(onMessage: _onMessage, onConnectionChange: _onConnectionChange);
      });
    });
  }
}
