import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lambo_server/lambo_server_core.dart';
import 'package:lambo_server/message_model.dart';
import 'package:test/test.dart';

void main() {
  late LamboServer server;
  const port = 8081; // Use a different port for tests
  const roomCode = 'test-room';
  final uri = 'ws://127.0.0.1:$port/ws/pcautomation/$roomCode';

  setUpAll(() async {
    server = LamboServer();
    // Start server in background
    unawaited(server.start(port: port));
    // Small delay to ensure server is bound
    await Future.delayed(const Duration(milliseconds: 500));
  });

  tearDownAll(() async {
    await server.stop();
  });

  test('Master-Slave communication works', () async {
    final masterSocket = await WebSocket.connect('$uri?role=master');
    final slaveSocket = await WebSocket.connect('$uri?role=slave');

    final completer = Completer<String>();
    slaveSocket.listen((data) {
      completer.complete(data as String);
    });

    final message = MessageModel(
      event: 'action',
      payload: {'data': 'hello'}
    );
    masterSocket.add(jsonEncode(message.toMap()));

    final received = await completer.future.timeout(const Duration(seconds: 2));
    final receivedModel = MessageModel.fromJson(jsonDecode(received));

    expect(receivedModel.event, equals('action'));
    expect(receivedModel.payload['data'], equals('hello'));

    await masterSocket.close();
    await slaveSocket.close();
  });

  test('Late joiner receives room state', () async {
    final masterSocket = await WebSocket.connect('$uri?role=master');

    final stateMessage = MessageModel(
      event: 'room-state',
      payload: {'state': 'ready'}
    );
    masterSocket.add(jsonEncode(stateMessage.toMap()));

    // Wait for server to process state
    await Future.delayed(const Duration(milliseconds: 500));

    final slaveSocket = await WebSocket.connect('$uri?role=slave');
    final completer = Completer<String>();
    slaveSocket.listen((data) {
      completer.complete(data as String);
    });

    final received = await completer.future.timeout(const Duration(seconds: 2));
    final receivedModel = MessageModel.fromJson(jsonDecode(received));

    expect(receivedModel.event, equals('room-state'));
    expect(receivedModel.payload['state'], equals('ready'));

    await masterSocket.close();
    await slaveSocket.close();
  });

  test('Invalid room code is rejected', () async {
    try {
      await WebSocket.connect('ws://127.0.0.1:$port/ws/pcautomation/invalid!!!');
      fail('Should have thrown an exception');
    } catch (e) {
      expect(e, anyOf(isA<WebSocketException>(), isA<HttpException>()));
    }
  });

  test('HEAD / returns 200 OK', () async {
    final client = HttpClient();
    final request = await client.head('127.0.0.1', port, '/');
    final response = await request.close();
    
    expect(response.statusCode, equals(HttpStatus.ok));
    client.close();
  });

  test('POST /api/event/<code>/<event>/ broadcasts to WebSocket', () async {
    final roomCode = 'http-test-room';
    final slaveSocket = await WebSocket.connect('ws://127.0.0.1:$port/ws/pcautomation/$roomCode?role=slave');
    
    final completer = Completer<String>();
    slaveSocket.listen((data) {
      completer.complete(data as String);
    });

    final client = HttpClient();
    final request = await client.post('127.0.0.1', port, '/api/event/$roomCode/click');
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'foo': 'bar'}));
    final response = await request.close();

    expect(response.statusCode, equals(HttpStatus.ok));
    
    final received = await completer.future.timeout(const Duration(seconds: 2));
    final receivedModel = MessageModel.fromJson(jsonDecode(received));

    expect(receivedModel.event, equals('click'));
    expect(receivedModel.payload['foo'], equals('bar'));

    await slaveSocket.close();
    client.close();
  });

  test('POST to non-existent room returns 404', () async {
    final client = HttpClient();
    final request = await client.post('127.0.0.1', port, '/api/event/non-existent-room/click');
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'foo': 'bar'}));
    final response = await request.close();

    expect(response.statusCode, equals(HttpStatus.notFound));
    client.close();
  });
}
