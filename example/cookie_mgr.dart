import 'package:cookie_jar/cookie_jar.dart';
import 'package:web/web.dart';
import 'package:web_cookie_manager/dio_cookie_manager.dart';

main() async {
  var web = Web();
  var cookieJar = CookieJar();
  web.interceptors..add(LogInterceptor())..add(CookieManager(cookieJar));
  await web.get("https://google.com/");
  // Print cookies
  print(cookieJar.loadForRequest(Uri.parse("https://google.com/")));
  // second request with the cookie
  await web.get("https://google.com/");
}
