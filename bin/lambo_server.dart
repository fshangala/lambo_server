import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';

import 'package:lambo_server/lambo_client_model.dart';
import 'package:lambo_server/lambo_room.dart';
import 'package:lambo_server/message_model.dart';

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Server listening on ws://0.0.0.0:8080');

  List<LamboRoom> lamboRooms = [];

  await for (HttpRequest request in server) {
    final path = request.uri.path;

    if (WebSocketTransformer.isUpgradeRequest(request) && path.startsWith('/ws/pcautomation/')) {
      String? roomCode;
      roomCode = request.uri.pathSegments.length > 2 ? request.uri.pathSegments[2] : null;

      if (request.connectionInfo != null && roomCode != null) {

        // Extract the room from the path
        LamboRoom? lamboRoom; 
        for (var room in lamboRooms) {
          if (room.code == roomCode) {
            lamboRoom = room;
            break;
          }
        }
        if (lamboRoom == null) {
          lamboRoom = LamboRoom(code: roomCode);
          lamboRooms.add(lamboRoom);
        }

        WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
          final lamboClientModel = LamboClientModel(
            address: request.connectionInfo!.remoteAddress.address, 
            code: roomCode!,
            webSocket: webSocket,
          );
          lamboRoom!.join(lamboClientModel);
          print(lamboClientModel);

          webSocket.listen((message) {
            final messageModel = MessageModel.fromJson(jsonDecode(message));
            print('Received message: $messageModel');

            switch (messageModel.eventType) {
              case 'connection':
                break;

              default:
                lamboRoom?.sendMessage(messageModel);
                break;
            }

          }, onDone: () {
            print('Client disconnected: ${request.connectionInfo?.remoteAddress.address}');
          }, onError: (error, stackTrace) {
            Logger().e('WebSocket error', error: error, stackTrace: stackTrace);
          }, cancelOnError: true,);
        });
      } else {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('client: ${request.connectionInfo?.remoteAddress.address}, room-code: $roomCode')
          ..close();
      }
    } else {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('WebSocket connections only')
        ..close();
    }
  }
}
