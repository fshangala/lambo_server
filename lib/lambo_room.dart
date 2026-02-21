import 'package:lambo_server/lambo_client_model.dart';
import 'package:lambo_server/message_model.dart';
import 'package:logger/logger.dart';

class LamboRoom {
  final String code;
  final List<LamboClientModel> _members = [];

  LamboRoom({
    required this.code,
  });

  void join(LamboClientModel member) {
    _members.add(member);
  }

  void leave(LamboClientModel member) {
    try {
      _members.remove(member);
    } on StateError catch(e, stackTrace) {
      Logger().w('Failed to remove member from room: $member', error: e, stackTrace: stackTrace);
    }
  }

  void sendMessage(MessageModel message) {
    for (var member in _members) {
      member.webSocket.add(message.toString());
    }
  }
}