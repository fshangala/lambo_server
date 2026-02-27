import 'dart:convert';
import 'package:lambo_server/lambo_client_model.dart';
import 'package:lambo_server/message_model.dart';
import 'package:logger/logger.dart';

class LamboRoom {
  final String code;
  final List<LamboClientModel> _members = [];
  MessageModel? _lastState;

  LamboRoom({
    required this.code,
  });

  void join(LamboClientModel member) {
    _members.add(member);
    if (member.role == 'slave' && _lastState != null) {
      member.webSocket.add(jsonEncode(_lastState!.toMap()));
    }
  }

  void leave(LamboClientModel member) {
    try {
      _members.remove(member);
    } on StateError catch(e, stackTrace) {
      Logger().w('Failed to remove member from room: $member', error: e, stackTrace: stackTrace);
    }
  }

  void updateRoomState(MessageModel message) {
    _lastState = message;
  }

  void sendMessage(MessageModel message) {
    for (var member in _members) {
      member.webSocket.add(jsonEncode(message.toMap()));
    }
  }
}