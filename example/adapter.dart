import 'dart:async';

import 'package:web/adapter.dart';
import 'package:web/web.dart';

class MyAdapter extends HttpClientAdapter {
  final DefaultHttpClientAdapter _adapter = DefaultHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>> requestStream, Future? cancelFuture) async {
    final uri = options.uri;
    // hook requests to  google.com
    if (uri.host == "google.com") {
      return ResponseBody.fromString("Too young too simple!", 200);
    }
    return _adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}

void main() async {
  final web = Web();
  web.httpClientAdapter = MyAdapter();
  var response = await web.get("https://google.com");
  print(response);
  response = await web.get("https://google.com");
  print(response);
}
