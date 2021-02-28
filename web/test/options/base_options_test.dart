import 'package:test/test.dart';
import 'package:web/src/options/base_options.dart';

void main() {
  group('Base Options should', () {
    test('merge old options by creating new option with the provided values',
        () {
      final map = {'a': '5'};
      final mapOverride = {'b': '6'};
      final baseOptions = BaseOptions(
        connectTimeout: 2000,
        receiveTimeout: 2000,
        sendTimeout: 2000,
        baseUrl: 'http://localhost',
        queryParameters: map,
        extra: map,
        headers: map,
        contentType: 'application/json',
        followRedirects: false,
      );
      final mergedOptions = baseOptions.merge(
        method: 'post',
        receiveTimeout: 3000,
        sendTimeout: 3000,
        baseUrl: 'https://tautalos.club',
        extra: mapOverride,
        headers: mapOverride,
        contentType: 'text/html',
      );
      expect(mergedOptions.method, 'post');
      expect(mergedOptions.receiveTimeout, 3000);
      expect(mergedOptions.connectTimeout, 2000);
      expect(mergedOptions.followRedirects, false);
      expect(mergedOptions.baseUrl, 'https://tautalos.club');
      expect(mergedOptions.headers['b'], '6');
      expect(mergedOptions.extra['b'], '6');
      expect(mergedOptions.queryParameters['b'], null);
      expect(mergedOptions.contentType, 'text/html');
    });
  });
}
