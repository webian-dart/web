import 'package:test/test.dart';
import 'package:web/src/headers/headers.dart';

void main() {
  group('Headers Should', () {
    test('headers should be iterable', () {
      var headers = Headers.fromMap({
        'set-cookie': ['k=v', 'k1=v1'],
        'content-length': ['200'],
        'test': ['1', '2'],
      });

      var ls = [];
      headers.forEach((k, list) {
        ls.addAll(list);
      });
    });

    test('get us a header value', () {
      var headers = Headers.fromMap({
        'content-length': ['200'],
      });
      expect(headers.valueOf('content-length'), '200');
    });

    test('set new header value', () {
      var headers = Headers.fromMap({
        'set-cookie': ['k=v', 'k1=v1'],
        'content-length': ['200'],
        'test': ['1', '2'],
      });

      headers.set('content-length', '300');
      expect(headers.valueOf('content-length'), '300');

      headers.set('content-length', ['400']);
      expect(headers.valueOf('content-length'), '400');
    });

    test('add value to Header', () {
      var headers = Headers.fromMap({
        'set-cookie': ['k=v', 'k1=v1']
      });
      headers.add('SET-COOKIE', 'k2=v2');
      expect(headers['set-cookie']!.length, 3);
      expect(headers['set-cookie']![2], 'k2=v2');
    });

    test('add new headers always with lowercase names', () {
      var headers = Headers.fromMap({
        'set-cookie': ['k=v', 'k1=v1'],
      });
      headers.add('SET-COOKIE', 'k2=v2');
      expect(headers['set-cookie']!.length, 3);
      expect(headers['set-cookie']![2], 'k2=v2');
    });

    test('removed from an Header a specified value', () {
      var headers = Headers.fromMap({
        'set-cookie': ['k=v', 'k1=v1']
      });
      headers.remove('set-cookie', 'k=v');
      expect(headers['set-cookie']?.length, 1);
    });

    test('removed all values of provided Header by setting them to null', () {
      var headers = Headers.fromMap({
        'set-cookie': ['k=v', 'k1=v1'],
        'content-length': ['200'],
        'test': ['1', '2'],
      });

      headers.removeAll('set-cookie');
      expect(headers['set-cookie'], null);

      headers.removeAll('content-length');
      expect(headers['content-length'], null);

      headers.removeAll('test');
      expect(headers['test'], null);
    });

    test('throws and when trying to extract a Header with a list of value ',
        () {
      var headers = Headers.fromMap({
        'set-cookie': ['k=v', 'k1=v1'],
        'content-length': ['200'],
        'test': ['1', '2'],
      });
      expect(Future(() => headers.valueOf('test')), throwsException);
    });

    test('clear the headers', () {
      var headers = Headers();
      headers.set('xx', 'v');
      expect(headers.valueOf('xx'), 'v');
      headers.clear();
      expect(headers.map.isEmpty, true);
    });

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

    test('give as a correctly formatted string version with all the Headers',
        () {
      var headers = Headers.fromMap({
        'set-cookie': ['k=v', 'k1=v1'],
        'content-length': ['200'],
        'test': ['1', '2'],
      });

      expect(
          headers.toString(),
          'set-cookie: k=v\n'
          'set-cookie: k1=v1\n'
          'content-length: 200\n'
          'test: 1\n'
          'test: 2\n');
    });
  });
}
