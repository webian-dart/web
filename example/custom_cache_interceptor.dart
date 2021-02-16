import 'dart:async';

import 'package:dio/dio.dart';

class CacheInterceptor extends Interceptor {
  CacheInterceptor();

  final _cache = <Uri, Response>{};

  @override
  Future onRequest(RequestOptions options) async {
    final response = _cache[options.uri];
    if (options.extra["refresh"] == true) {
      print("${options.uri}: force refresh, ignore cache! \n");
      return options;
    } else if (response != null) {
      print("cache hit: ${options.uri} \n");
      return response;
    }
  }

  @override
  Future onResponse(Response response) async {
    _cache[response.request!.uri] = response;
  }

  @override
  Future onError(DioError e) async {
    print('onError: $e');
  }
}

main() async {
  var dio = Dio();
  dio.options.baseUrl = "https://google.com";
  dio.interceptors
    ..add(CacheInterceptor())
    ..add(LogInterceptor(requestHeader: false, responseHeader: false));

  await dio.get("/"); // second request
  await dio.get("/"); // Will hit cache
  // Force refresh
  await dio.get("/", options: Options(extra: {'refresh': true}));
}
