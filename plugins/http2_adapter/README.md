# Http2Adapter [![Pub](https://img.shields.io/pub/v/web_http2_adapter.svg?style=flat-square)](https://pub.dartlang.org/packages/web_http2_adapter)

A Web [HttpClientAdapter](https://github.com/tautalos/web#httpclientadapter) which implements Http/2.0 .

## Getting Started

### Install

```yaml
dependencies:
  web_http2_adapter: x.x.x  #latest version
```

### Usage

```dart
import 'package:web/web.dart';
import 'package:web_http2_adapter/http2.dart';

main() async {
  var web = Web()
    ..options.baseUrl = "https://www.ustc.edu.cn/"
    ..httpClientAdapter = Http2Adapter();

  Response<String> response;
  response = await web.get("/?xx=6");
  print(response.data);
  response = await web.get("2062/list.htm");
  print(response.data);
}

```

## ConnectionManager

ConnectionManager is used to manager the connections that should be reusable. The main responsibility of ConnectionManager is to implement a connection reuse strategy for http2.

```dart
web.httpClientAdapter = Http2Adapter(
  ConnectionManager(
    idleTimeout: 10000,
    /// Ignore bad certificate
    onClientCreate: (_, clientSetting) => clientSetting.onBadCertificate = (_) => true,
  ),
);
```

- `idleTimeout`： Sets the idle timeout(milliseconds) of non-active persistent connections. For the sake of socket reuse feature with http/2, the value should not be less than 1000 (1s).
- `onClientCreate`：Callback when socket created. We can set trusted certificates and handler for unverifiable certificates.

You can also custom a connection manager with a specific connection reuse strategy  by implementing  the `ConnectionManager`.


