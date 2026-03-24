import 'package:lambo_server/lambo_server_core.dart';

void main() async {
  final server = LamboServer();
  await server.start();
}
