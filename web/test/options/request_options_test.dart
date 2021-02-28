import 'package:test/test.dart';
import 'package:web/src/options/request_options.dart';

void main() {
  group('Request Options should ', () {
    test('merge old options by creating new option with the provided values',
        () {
      final mapOverride = {'b': '6'};
      var opt4 = RequestOptions(
        sendTimeout: 2000,
        followRedirects: false,
      );
      var opt5 = opt4.merge(
        method: 'post',
        receiveTimeout: 3000,
        sendTimeout: 3000,
        extra: mapOverride,
        headers: mapOverride,
        data: 'xx=5',
        path: '/',
        contentType: 'text/html',
      );
      assert(opt5.method == 'post');
      assert(opt5.receiveTimeout == 3000);
      assert(opt5.followRedirects == false);
      assert(opt5.contentType == 'text/html');
      assert(opt5.headers['b'] == '6');
      assert(opt5.extra['b'] == '6');
      assert(opt5.data == 'xx=5');
      assert(opt5.path == '/');
    });
  });
}
