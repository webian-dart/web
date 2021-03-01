import 'package:test/test.dart';
import 'package:web/web.dart';

void main() {
  group('Transformer should ', () {
    test('encode a map correctly', () {
      var data = {
        'a': '你好',
        'b': [5, '6'],
        'c': {
          'd': 8,
          'e': {
            'a': 5,
            'b': [66, 8]
          }
        }
      };
      var result =
          'a=%E4%BD%A0%E5%A5%BD&b%5B%5D=5&b%5B%5D=6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D%5B%5D=66&c%5Be%5D%5Bb%5D%5B%5D=8';
      expect(Transformer.urlEncodeMap(data), result);
    });
  });
}
