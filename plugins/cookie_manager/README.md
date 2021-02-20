# web_cookie_manager [![Pub](https://img.shields.io/pub/v/web_cookie_manager.svg?style=flat-square)](https://pub.dartlang.org/packages/web_cookie_manager)

A  cookie manager for [Web](https://github.com/tautalos/web).

## Getting Started

### Install

```yaml
dependencies:
  web_cookie_manager: ^1.0.0  #latest version
```

### Usage

```dart
import 'package:web/web.dart';
import 'package:web_cookie_manager/web_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

main() async {
  var web =  Web();
  var cookieJar=CookieJar();
  web.interceptors.add(CookieManager(cookieJar));
  // Print cookies
  print(cookieJar.loadForRequest(Uri.parse("https://google.com/")));
  // second request with the cookie
  await web.get("https://google.com/");
  ... 
}
```

## Cookie Manager

CookieManager Interceptor can help us manage the request/response cookies automaticly. CookieManager depends on `cookieJar` package :

> The web_cookie_manager  manage API is based on the withdrawn [cookie_jar](https://github.com/tautalos/cookie_jar).

You can create a `CookieJar` or `PersistCookieJar` to manage cookies automatically, and web use the `CookieJar` by default, which saves the cookies **in RAM**. If you want to persists cookies, you can use the `PersistCookieJar` class, for example:

```dart
web.interceptors.add(CookieManager(PersistCookieJar()))
```

`PersistCookieJar` persists the cookies in files, so if the application exit, the cookies always exist unless call `delete` explicitly.

> Note: In flutter, the path passed to `PersistCookieJar` must be valid(exists in phones and with write access). you can use [path_provider](https://pub.dartlang.org/packages/path_provider) package to get right path.

In flutter: 

```dart
Directory appDocDir = await getApplicationDocumentsDirectory();
String appDocPath = appDocDir.path;
var cookieJar=PersistCookieJar(dir:appdocPath+"/.cookies/");
web.interceptors.add(CookieManager(cookieJar));
...
```
