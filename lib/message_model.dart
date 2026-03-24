class MessageModel {
  final String eventType;
  final String event;
  final List<String> args;
  final Map<String, dynamic> kwargs;

  MessageModel({
    required this.eventType,
    required this.event,
    required this.args,
    required this.kwargs,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    try {
      return MessageModel(
        eventType: json['event_type'] as String? ?? 'default',
        event: json['event'] as String? ?? '',
        args: json['args'] != null ? List<String>.from(json['args'] as Iterable) : [],
        kwargs: json['kwargs'] != null ? Map<String, dynamic>.from(json['kwargs'] as Map) : {},
      );
    } catch (e) {
      throw FormatException('Invalid message format: $e');
    }
  }

  void validate() {
    if (eventType.isEmpty) {
      throw const FormatException('eventType cannot be empty');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'event_type': eventType,
      'event': event,
      'args': args,
      'kwargs': kwargs,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
