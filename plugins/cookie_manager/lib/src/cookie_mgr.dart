import 'dart:async';
import 'dart:io';

import 'package:web/web.dart';
import 'package:web_cookies/web_cookies.dart';

/// Don't use this class in Browser environment
class CookieManager extends Interceptor {
  /// Cookie manager for http requests。Learn more details about
  /// WebCookies please refer to [web_cookies](https://github.com/tautalos/web_cookies)
  final WebCookies webCookies;

  CookieManager(this.webCookies);

  @override
  Future onRequest(RequestOptions options) async {
    var cookies = webCookies.loadForRequest(options.uri);
    cookies.removeWhere((cookie) {
      if (cookie.expires != null) {
        return cookie.expires?.isBefore(DateTime.now()) ?? false;
      }
      return false;
    });
    final cookie = getCookies(cookies);
    if (cookie.isNotEmpty) options.headers[HttpHeaders.cookieHeader] = cookie;
  }

  @override
  Future onResponse(Response response) async => _saveCookies(response);

  @override
  Future onError(Fault err) async => _saveCookies(err.response);

  void _saveCookies(Response? response) {
    if (response?.headers != null) {
      final cookies = response?.headers[HttpHeaders.setCookieHeader];
      if (cookies != null) {
        webCookies.saveFromResponse(
          response?.request?.uri ?? Uri(),
          cookies.map((str) => Cookie.fromSetCookieValue(str)).toList(),
        );
      }
    }
  }

  static String getCookies(List<Cookie> cookies) {
    return cookies.map((cookie) => "${cookie.name}=${cookie.value}").join('; ');
  }
}
