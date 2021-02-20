import 'package:test/test.dart';
import 'package:web/web.dart';

void main() {
  test('catch Fault', () async {
    dynamic error;

    try {
      await Web().get('https://does.not.exist');
      fail('did not throw');
    } on Fault catch (e) {
      error = e;
    }

    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  });

  test('catch Fault as Exception', () async {
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
