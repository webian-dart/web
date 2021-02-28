import 'package:test/test.dart';
import 'package:web/src/requests/request_config.dart';

void main() {
  group('Request Configs should ', () {
    test('have a case insensitive header', () {
      final itWasFound = 'itWasFound';
      final one = RequestConfig(headers: {'SomeHeader': itWasFound});
      final two = RequestConfig(headers: {'SOMEHEADER': itWasFound});
      expect(one.headers, two.headers);
    });
  });
}
