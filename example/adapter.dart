import 'dart:async';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';

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
  final dio = Dio();
  dio.httpClientAdapter = MyAdapter();
  var response = await dio.get("https://google.com");
  print(response);
  response = await dio.get("https://google.com");
  print(response);
}
