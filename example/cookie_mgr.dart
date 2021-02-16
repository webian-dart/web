import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

main() async {
  var dio = Dio();
  var cookieJar = CookieJar();
  dio.interceptors..add(LogInterceptor())..add(CookieManager(cookieJar));
  await dio.get("https://google.com/");
  // Print cookies
  print(cookieJar.loadForRequest(Uri.parse("https://google.com/")));
  // second request with the cookie
  await dio.get("https://google.com/");
}
