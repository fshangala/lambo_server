import 'dart:io';

class LamboClientModel {
  final String address;
  final String code;
  final String role;
  final WebSocket webSocket;

  LamboClientModel({
    required this.address,
    required this.code,
    required this.role,
    required this.webSocket,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'code': code,
      'role': role,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}