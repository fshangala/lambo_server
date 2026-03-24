import 'package:lambo_server/message_model.dart';
import 'package:test/test.dart';

void main() {
  group('MessageModel', () {
    test('fromJson creates a valid model from JSON', () {
      final json = {
        'event_type': 'test_event',
        'event': 'action',
        'args': ['arg1'],
        'kwargs': {'key': 'value'}
      };
      final model = MessageModel.fromJson(json);
      expect(model.eventType, equals('test_event'));
      expect(model.event, equals('action'));
      expect(model.args, equals(['arg1']));
      expect(model.kwargs, equals({'key': 'value'}));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final model = MessageModel.fromJson(json);
      expect(model.eventType, equals('default'));
      expect(model.event, equals(''));
      expect(model.args, isEmpty);
      expect(model.kwargs, isEmpty);
    });

    test('validate throws FormatException if eventType is empty', () {
      final model = MessageModel(eventType: '', event: '', args: [], kwargs: {});
      expect(() => model.validate(), throwsA(isA<FormatException>()));
    });

    test('toMap returns a valid map', () {
      final model = MessageModel(
        eventType: 'type',
        event: 'event',
        args: ['a'],
        kwargs: {'k': 'v'}
      );
      final map = model.toMap();
      expect(map['event_type'], equals('type'));
      expect(map['event'], equals('event'));
      expect(map['args'], equals(['a']));
      expect(map['kwargs'], equals({'k': 'v'}));
    });
  });
}
