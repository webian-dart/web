import 'package:cookie_manager/web_cookie_manager.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';
import 'package:web_cookies/web_cookies.dart';

void main() {
  test('cookie-jar', () async {
    var web = Web();
    var webCookies = WebCookies();
    web.interceptors..add(CookieManager(webCookies))..add(LogInterceptor());
    await web.get('https://google.com/');
    // Print cookies
    print(webCookies.loadForRequest(Uri.parse('https://google.com/')));
    // second request with the cookie
    await web.get('https://google.com/');
  });
}
