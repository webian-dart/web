# cookie_manager [![Pub](https://img.shields.io/pub/v/cookie_manager.svg?style=flat-square)](https://pub.dartlang.org/packages/cookie_manager)

A  cookie manager for [Web](https://github.com/tautalos/web).

## Getting Started

### Install

```yaml
dependencies:
  cookie_manager: ^1.0.0  #latest version
```

### Usage

```dart
import 'package:web/web.dart';
import 'package:cookie_manager/cookie_manager.dart';
import 'package:web_cookies/web_cookies.dart';

main() async {
  var web =  Web();
  var webCookies=WebCookies();
  web.interceptors.add(CookieManager(webCookies));
  // Print cookies
  print(webCookies.loadForRequest(Uri.parse("https://google.com/")));
  // second request with the cookie
  await web.get("https://google.com/");
  ... 
}
```

## Cookie Manager

CookieManager Interceptor can help us manage the request/response cookies automaticly. CookieManager depends on `webCookies` package :

> The cookie_manager  manage API is based on the withdrawn [web_cookies](https://github.com/tautalos/web_cookies).

You can create a `WebCookies` or `PersistWebCookies` to manage cookies automatically, and web use the `WebCookies` by default, which saves the cookies **in RAM**. If you want to persists cookies, you can use the `PersistWebCookies` class, for example:

```dart
web.interceptors.add(CookieManager(PersistWebCookies()))
```

`PersistWebCookies` persists the cookies in files, so if the application exit, the cookies always exist unless call `delete` explicitly.

> Note: In flutter, the path passed to `PersistWebCookies` must be valid(exists in phones and with write access). you can use [path_provider](https://pub.dartlang.org/packages/path_provider) package to get right path.

In flutter: 

```dart
Directory appDocDir = await getApplicationDocumentsDirectory();
String appDocPath = appDocDir.path;
var webCookies=PersistWebCookies(dir:appdocPath+"/.cookies/");
web.interceptors.add(CookieManager(webCookies));
...
```
