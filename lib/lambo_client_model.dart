import 'dart:io';

class LamboClientModel {
  final String address;
  final String code;
  final WebSocket webSocket;

  LamboClientModel({
    required this.address,
    required this.code,
    required this.webSocket,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'code': code,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}