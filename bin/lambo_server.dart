import 'package:dotenv/dotenv.dart';
import 'package:lambo_server/lambo_server_core.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final server = LamboServer();
  
  await server.start(
    address: env['LAMBO_HOST'],
    port: int.tryParse(env['LAMBO_PORT'] ?? ''),
  );
}
