import 'package:Web/Web.dart';
import 'package:test/test.dart';

void main() {
  test('catch WebError', () async {
    dynamic error;

    try {
      await Web().get('https://does.not.exist');
      fail('did not throw');
    } on WebError catch (e) {
      error = e;
    }

    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  });

  test('catch WebError as Exception', () async {
    dynamic error;

    try {
      await Web().get('https://does.not.exist');
      fail('did not throw');
    } on Exception catch (e) {
      error = e;
    }

    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  });
}
