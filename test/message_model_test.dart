import 'package:lambo_server/message_model.dart';
import 'package:test/test.dart';

void main() {
  group('MessageModel', () {
    test('fromJson creates a valid model from JSON', () {
      final json = {
        'event': 'action',
        'payload': {'key': 'value'}
      };
      final model = MessageModel.fromJson(json);
      expect(model.event, equals('action'));
      expect(model.payload, equals({'key': 'value'}));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final model = MessageModel.fromJson(json);
      expect(model.event, equals(''));
      expect(model.payload, isEmpty);
    });

    test('validate throws FormatException if event is empty', () {
      final model = MessageModel(event: '', payload: {});
      expect(() => model.validate(), throwsA(isA<FormatException>()));
    });

    test('toMap returns a valid map', () {
      final model = MessageModel(
        event: 'event',
        payload: {'k': 'v'}
      );
      final map = model.toMap();
      expect(map['event'], equals('event'));
      expect(map['payload'], equals({'k': 'v'}));
    });
  });
}
