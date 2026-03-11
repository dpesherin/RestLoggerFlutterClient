import 'package:socket_io_client/socket_io_client.dart' as socket_io;

class SafeSocket {
  final socket_io.Socket _socket;

  SafeSocket._internal(this._socket);

  static SafeSocket io(String uri, [Map<String, dynamic>? opts]) {
    try {
      final socket = socket_io.io(uri, opts);
      return SafeSocket._internal(socket);
    } catch (e) {
      if (e.toString().contains('RangeError')) {
        final socket = socket_io.io(uri, opts);
        return SafeSocket._internal(socket);
      }
      rethrow;
    }
  }

  void on(String event, dynamic Function(dynamic) handler) {
    try {
      _socket.on(event, (data) {
        try {
          handler(data);
        } catch (e) {
          if (!e.toString().contains('RangeError')) {}
        }
      });
    } catch (e) {
      if (!e.toString().contains('RangeError')) {}
    }
  }

  void once(String event, dynamic Function(dynamic) handler) {
    try {
      _socket.once(event, (data) {
        try {
          handler(data);
        } catch (e) {
          if (!e.toString().contains('RangeError')) {}
        }
      });
    } catch (e) {
      if (!e.toString().contains('RangeError')) {}
    }
  }

  void connect() {
    try {
      _socket.connect();
    } catch (e) {
      if (!e.toString().contains('RangeError')) {}
    }
  }

  void disconnect() {
    try {
      _socket.disconnect();
    } catch (e) {
      if (!e.toString().contains('RangeError')) {}
    }
  }

  void close() {
    try {
      _socket.close();
    } catch (e) {
      if (!e.toString().contains('RangeError')) {}
    }
  }

  bool get connected => _socket.connected;
}
