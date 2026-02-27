import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:lambo_server/message_model.dart';

void main() async {
  // Configuration
  const serverIp = '127.0.0.1';
  const port = 8080;
  const roomCode = 'test-room';
  
  final uri = 'ws://$serverIp:$port/ws/pcautomation/$roomCode';

  try {
    print('--- Starting Client Test ---');

    // 1. Connect Master
    print('[Master] Connecting to $uri?role=master...');
    final masterSocket = await WebSocket.connect('$uri?role=master');
    print('[Master] Connected.');

    // 2. Connect Slave 1
    print('[Slave 1] Connecting to $uri?role=slave...');
    final slave1Socket = await WebSocket.connect('$uri?role=slave');
    print('[Slave 1] Connected.');

    // Listen to Slave 1 messages
    slave1Socket.listen((message) {
      final messageModel = MessageModel.fromJson(jsonDecode(message));
      print('[Slave 1] Received: ${messageModel.toMap()}');
    });

    // 3. Master sends a set_url command
    // Note: Ensure the keys here match what your MessageModel expects
    final messageModel = MessageModel(
      eventType: 'set_url',
      event: 'default',
      args: [],
      kwargs: {
        'payload': 'https://example.com',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    final setUrlMessage = jsonEncode(messageModel.toMap());

    print('[Master] Sending: $setUrlMessage');
    masterSocket.add(setUrlMessage);

    // Wait for message to propagate
    await Future.delayed(Duration(seconds: 2));

    // 4. Connect Slave 2 (Late joiner)
    // This tests if the server sends the cached state to new slaves
    print('[Slave 2] Connecting (Late joiner)...');
    final slave2Socket = await WebSocket.connect('$uri?role=slave');
    print('[Slave 2] Connected.');

    slave2Socket.listen((message) {
      final messageModel = MessageModel.fromJson(jsonDecode(message));
      print('[Slave 2] Received (should be cached state): ${messageModel.toMap()}');
    });

    // Keep alive briefly to receive messages
    await Future.delayed(Duration(seconds: 2));
    print('--- Test Complete ---');
    exit(0);

  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}