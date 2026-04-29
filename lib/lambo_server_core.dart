import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';

import 'lambo_client_model.dart';
import 'lambo_room.dart';
import 'message_model.dart';

class LamboServer {
  final Map<String, LamboRoom> _rooms = {};
  HttpServer? _server;
  final Logger _logger = Logger();
  
  static final RegExp _roomCodeRegExp = RegExp(r'^[a-zA-Z0-9_-]+$');
  final Map<LamboClientModel, List<DateTime>> _clientMessageTimestamps = {};
  static const int _maxMessagesPerSecond = 50;

  Future<void> start({String? address, int? port}) async {
    final effectiveAddress = address ?? Platform.environment['LAMBO_HOST'] ?? '0.0.0.0';
    final effectivePort = port ?? int.tryParse(Platform.environment['LAMBO_PORT'] ?? '8080') ?? 8080;

    _server = await HttpServer.bind(effectiveAddress, effectivePort);
    
    print('-----------------------------------------');
    print('Server listening on:');
    
    if (effectiveAddress == '0.0.0.0') {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          print('  IP:${addr.address}\tPORT:$effectivePort');
        }
      }
    } else {
      print('  IP:$effectiveAddress\tPORT:$effectivePort');
    }
    print('-----------------------------------------');
    print('WebSocket route: /ws/pcautomation/<room-code>?role=<master|slave>');
    print('HTTP route: /api/event/<room-code>/<event-name>');
    print('-----------------------------------------');

    await for (HttpRequest request in _server!) {
      _handleRequest(request);
    }
  }

  void _handleRequest(HttpRequest request) {
    final path = request.uri.path;
    final method = request.method;

    if (method == 'HEAD' && path == '/') {
      request.response
        ..statusCode = HttpStatus.ok
        ..close();
      return;
    }

    if (method == 'POST' && path.startsWith('/api/event/')) {
      _handleEventPost(request);
      return;
    }

    if (WebSocketTransformer.isUpgradeRequest(request) && path.startsWith('/ws/pcautomation/')) {
      final segments = request.uri.pathSegments;
      final roomCode = segments.length > 2 ? segments[2] : null;

      if (request.connectionInfo != null && roomCode != null && _roomCodeRegExp.hasMatch(roomCode)) {
        _upgradeToWebSocket(request, roomCode);
      } else {
        _rejectRequest(request, 'Forbidden: Invalid or missing room code');
      }
    } else {
      _rejectRequest(request, 'Forbidden: WebSocket connections only');
    }
  }

  Future<void> _handleEventPost(HttpRequest request) async {
    final segments = request.uri.pathSegments;
    // Expected segments: ['api', 'event', '<code>', '<event>']
    if (segments.length < 4) {
      _rejectRequest(request, 'Invalid path', status: HttpStatus.badRequest);
      return;
    }

    final roomCode = segments[2];
    final event = segments[3];

    if (!_roomCodeRegExp.hasMatch(roomCode)) {
      _rejectRequest(request, 'Invalid room code', status: HttpStatus.badRequest);
      return;
    }

    final room = _rooms[roomCode];
    if (room == null) {
      _rejectRequest(request, 'Room not found', status: HttpStatus.notFound);
      return;
    }

    try {
      final content = await utf8.decoder.bind(request).join();
      final Map<String, dynamic> payload = content.isEmpty ? {} : jsonDecode(content) as Map<String, dynamic>;
      
      final messageModel = MessageModel(event: event, payload: payload);
      messageModel.validate();

      room.sendMessage(messageModel);
      _logger.d('Event "$event" posted to room $roomCode via HTTP POST');

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'status': 'success'}))
        ..close();
    } catch (e) {
      _rejectRequest(request, 'Invalid request: $e', status: HttpStatus.badRequest);
    }
  }

  void _upgradeToWebSocket(HttpRequest request, String roomCode) {
    WebSocketTransformer.upgrade(request).then((webSocket) {
      // Set heartbeat ping interval
      webSocket.pingInterval = const Duration(seconds: 20);

      final role = request.uri.queryParameters['role'] ?? 'slave';
      final client = LamboClientModel(
        address: request.connectionInfo!.remoteAddress.address,
        code: roomCode,
        role: role,
        webSocket: webSocket,
      );

      final room = _getOrCreateRoom(roomCode);
      room.join(client);
      print('Device connected: ${client.address} (${client.role}) in room $roomCode');

      webSocket.listen(
        (message) => _onMessage(room, client, message),
        onDone: () {
          _clientMessageTimestamps.remove(client);
          room.leave(client);
          print('Device disconnected: ${client.address} (${client.role}) from room $roomCode');
        },
        onError: (error) {
          _logger.e('WebSocket error for $client', error: error);
          _clientMessageTimestamps.remove(client);
          room.leave(client);
        },
        cancelOnError: true,
      );
    });
  }

  LamboRoom _getOrCreateRoom(String code) {
    return _rooms.putIfAbsent(
      code,
      () => LamboRoom(
        code: code,
        onEmpty: (emptyCode) {
          _rooms.remove(emptyCode);
          print('Room cleaned up: $emptyCode');
        },
      ),
    );
  }

  void _onMessage(LamboRoom room, LamboClientModel sender, dynamic message) {
    try {
      if (message is! String) {
        _logger.w('Received non-string message from ${sender.address}');
        return;
      }

      if (_isRateLimited(sender)) {
        _logger.w('Rate limit exceeded for ${sender.address}');
        return;
      }

      final messageModel = MessageModel.fromJson(jsonDecode(message));
      messageModel.validate();
      
      _logger.d('Received message in room ${room.code}: $message');

      switch (messageModel.event) {
        case 'connection':
          // Reserved for future use
          break;

        case 'room-state':
          room.updateRoomState(messageModel);
          // Broadcast to everyone to ensure all are in sync
          room.sendMessage(messageModel); 
          break;

        default:
          // Default behavior: broadcast to others
          room.sendMessage(messageModel, excludeSender: sender);
          break;
      }
    } catch (e, s) {
      _logger.e('Error processing message from ${sender.address}', error: e, stackTrace: s);
    }
  }

  bool _isRateLimited(LamboClientModel client) {
    final now = DateTime.now();
    final timestamps = _clientMessageTimestamps.putIfAbsent(client, () => []);
    
    // Remove timestamps older than 1 second
    timestamps.removeWhere((t) => now.difference(t).inSeconds >= 1);
    
    if (timestamps.length >= _maxMessagesPerSecond) {
      return true;
    }
    
    timestamps.add(now);
    return false;
  }

  void _rejectRequest(HttpRequest request, String reason, {int status = HttpStatus.forbidden}) {
    request.response
      ..statusCode = status
      ..write(reason)
      ..close();
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _rooms.clear();
    _clientMessageTimestamps.clear();
    _logger.i('Server stopped');
  }
}
