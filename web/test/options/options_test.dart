import 'package:test/test.dart';
import 'package:web/src/options/options.dart';

void main() {
  group('Options should', () {
    test('merge old options by creating new option with the provided values',
        () {
      final map = {'a': '5'};
      final mapOverride = {'b': '6'};

      final options = Options(
        method: 'get',
        receiveTimeout: 2000,
        sendTimeout: 2000,
        extra: map,
        headers: map,
        contentType: 'application/json',
        followRedirects: false,
      );
      final merged = options.merge(
        method: 'post',
        receiveTimeout: 3000,
        sendTimeout: 3000,
        extra: mapOverride,
        headers: mapOverride,
        contentType: 'text/html',
      );
      expect(merged.method, 'post');
      expect(merged.receiveTimeout, 3000);
      expect(merged.followRedirects, false);
      expect(merged.headers['b'], '6');
      expect(merged.extra['b'], '6');
      expect(merged.contentType, 'text/html');
    });
  });
}
