import '../utils/logger.dart';

class Message {
  final String? id;
  final dynamic mess;
  final dynamic msg;
  final String? module;
  final String? mode;
  final int timestamp;

  bool isPinned;
  int? pinnedAt;

  Message({
    this.id,
    this.mess,
    this.msg,
    this.module,
    this.mode,
    dynamic timestamp,
    this.isPinned = false,
    this.pinnedAt,
  }) : timestamp = _parseTimestamp(timestamp);

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString(),
      mess: json['mess'],
      msg: json['msg'],
      module: json['module'],
      mode: json['mode'],
      timestamp: json['timestamp'],
    );
  }

  static int _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now().millisecondsSinceEpoch;
    }

    if (timestamp is int) {
      return timestamp;
    }

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp).millisecondsSinceEpoch;
      } catch (e, stack) {
        logger.warning('Не удалось распарсить timestamp "$timestamp": $e');
        logger.debug(stack.toString());
      }
    }

    return DateTime.now().millisecondsSinceEpoch;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mess': mess,
      'msg': msg,
      'module': module,
      'mode': mode,
      'timestamp': timestamp,
    };
  }

  String get displayContent {
    if (mess != null) {
      return mess is Map ? mess.toString() : mess.toString();
    }
    if (msg != null) {
      return msg is Map ? msg.toString() : msg.toString();
    }
    return '';
  }

  String get moduleName => module ?? 'Unknown';

  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    }

    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool get isLightMode => mode == 'light' || mode == 'regular';

  Message copyWith({
    String? id,
    dynamic mess,
    dynamic msg,
    String? module,
    String? mode,
    dynamic timestamp,
    bool? isPinned,
    int? pinnedAt,
  }) {
    return Message(
      id: id ?? this.id,
      mess: mess ?? this.mess,
      msg: msg ?? this.msg,
      module: module ?? this.module,
      mode: mode ?? this.mode,
      timestamp: timestamp ?? this.timestamp,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
    );
  }
}
