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
    return MessageModel(
      eventType: json['event_type'],
      event: json['event'],
      args: List<String>.from(json['args']),
      kwargs: Map<String,dynamic>.from(json['kwargs']),
    );
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