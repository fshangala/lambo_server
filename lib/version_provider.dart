import 'dart:io';
import 'package:yaml/yaml.dart';

class VersionProvider {
  static String? _version;

  static Future<String> getVersion() async {
    if (_version != null) return _version!;

    try {
      final pubspecFile = File('pubspec.yaml');
      if (await pubspecFile.exists()) {
        final content = await pubspecFile.readAsString();
        final doc = loadYaml(content);
        _version = doc['version'] as String?;
      }
    } catch (_) {
      // Fallback if file reading fails
    }

    return _version ?? 'unknown';
  }
}
