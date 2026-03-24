import 'dart:io';
import 'package:lambo_server/lambo_client_model.dart';
import 'package:lambo_server/lambo_room.dart';
import 'package:lambo_server/message_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockWebSocket extends Mock implements WebSocket {}

void main() {
  group('LamboRoom', () {
    late MockWebSocket masterSocket;
    late MockWebSocket slaveSocket;
    late LamboClientModel master;
    late LamboClientModel slave;

    setUp(() {
      masterSocket = MockWebSocket();
      slaveSocket = MockWebSocket();
      master = LamboClientModel(
        address: '1.1.1.1',
        code: 'room1',
        role: 'master',
        webSocket: masterSocket,
      );
      slave = LamboClientModel(
        address: '2.2.2.2',
        code: 'room1',
        role: 'slave',
        webSocket: slaveSocket,
      );
    });

    test('join adds member to room', () {
      final room = LamboRoom(code: 'room1');
      room.join(master);
      expect(room.memberCount, equals(1));
    });

    test('leave removes member and triggers onEmpty', () {
      var onEmptyTriggered = false;
      final room = LamboRoom(
        code: 'room1',
        onEmpty: (code) => onEmptyTriggered = true,
      );
      room.join(master);
      room.leave(master);
      expect(room.memberCount, equals(0));
      expect(onEmptyTriggered, isTrue);
    });

    test('sendMessage broadcasts to all members', () {
      final room = LamboRoom(code: 'room1');
      room.join(master);
      room.join(slave);

      final message = MessageModel(eventType: 'test', event: '', args: [], kwargs: {});
      room.sendMessage(message);

      verify(() => masterSocket.add(any())).called(1);
      verify(() => slaveSocket.add(any())).called(1);
    });

    test('sendMessage can exclude sender', () {
      final room = LamboRoom(code: 'room1');
      room.join(master);
      room.join(slave);

      final message = MessageModel(eventType: 'test', event: '', args: [], kwargs: {});
      room.sendMessage(message, excludeSender: master);

      verifyNever(() => masterSocket.add(any()));
      verify(() => slaveSocket.add(any())).called(1);
    });

    test('join sends last state to new slaves', () {
      final room = LamboRoom(code: 'room1');
      final stateMessage = MessageModel(eventType: 'room-state', event: '', args: [], kwargs: {'foo': 'bar'});
      room.updateRoomState(stateMessage);

      room.join(slave);

      verify(() => slaveSocket.add(any())).called(1);
    });
  });
}
