class MessageModel {
  final String event;
  final Map<String, dynamic> payload;

  MessageModel({
    required this.event,
    required this.payload,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    try {
      return MessageModel(
        event: json['event'] as String? ?? '',
        payload: json['payload'] != null ? Map<String, dynamic>.from(json['payload'] as Map) : {},
      );
    } catch (e) {
      throw FormatException('Invalid message format: $e');
    }
  }

  void validate() {
    if (event.isEmpty) {
      throw const FormatException('event cannot be empty');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'event': event,
      'payload': payload,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
