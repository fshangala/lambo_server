import 'dart:io';
import 'package:logger/logger.dart';

/// Centralized logger for Lambo Server.
/// 
/// Configuration:
/// - [ProductionFilter]: Ensures logs are always captured.
/// - [SimplePrinter]: One-line logs with timestamps for better readability.
/// - [MultiOutput]: Logs to both the console and a local 'server.log' file.
final L = Logger(
  filter: ProductionFilter(),
  printer: SimplePrinter(
    printTime: true,
    colors: true,
  ),
  output: MultiOutput([
    ConsoleOutput(),
    FileOutput(file: File('server.log'), overrideExisting: false),
  ]),
);
