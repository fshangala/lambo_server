import 'dart:convert';
import 'package:lambo_server/lambo_client_model.dart';
import 'package:lambo_server/message_model.dart';
import 'package:lambo_server/logger.dart';

class LamboRoom {
  final String code;
  final List<LamboClientModel> _members = [];
  MessageModel? _lastState;
  final void Function(String)? onEmpty;

  LamboRoom({
    required this.code,
    this.onEmpty,
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
      if (_members.isEmpty && onEmpty != null) {
        onEmpty!(code);
      }
    } on StateError catch(e, stackTrace) {
      L.w('Failed to remove member from room: $member', error: e, stackTrace: stackTrace);
    }
  }

  void updateRoomState(MessageModel message) {
    _lastState = message;
  }

  void sendMessage(MessageModel message, {LamboClientModel? excludeSender}) {
    final encodedMessage = jsonEncode(message.toMap());
    for (var member in _members) {
      if (excludeSender != null && member == excludeSender) {
        continue;
      }
      member.webSocket.add(encodedMessage);
    }
  }

  int get memberCount => _members.length;
}
