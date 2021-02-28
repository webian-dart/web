import 'package:test/test.dart';
import 'package:web/src/headers.dart';

void main() {
  group('Headers Should', () {
    test('have insensitive keys', () {
      final itWasFound = 'itWasFound';
      final one = Headers.fromMap({
        'SomeHeader': [itWasFound]
      });
      final two = Headers.fromMap({
        'SOMEHEADER': [itWasFound]
      });
      expect(one.map, two.map);
    });
  });
}
