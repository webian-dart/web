import 'dart:async';

import 'package:web/web.dart';

class CacheInterceptor extends Interceptor {
  CacheInterceptor();

  final _cache = <Uri, Response>{};

  @override
  Future onRequest(RequestOptions options) async {
    final response = _cache[options.uri];
    if (options.extra['refresh'] == true) {
      print('${options.uri}: force refresh, ignore cache! \n');
      return options;
    } else if (response != null) {
      print('cache hit: ${options.uri} \n');
      return response;
    }
  }

  @override
  Future onResponse(Response response) async {
    _cache[response.request!.uri] = response;
  }

  @override
  Future onFault(Fault e) async {
    print('onError: $e');
  }
}

void main() async {
  var web = Web();
  web.options.baseUrl = 'https://google.com';
  web.interceptors
    ..add(CacheInterceptor())
    ..add(LogInterceptor(requestHeader: false, responseHeader: false));

  await web.get('/'); // second request
  await web.get('/'); // Will hit cache
  // Force refresh
  await web.get('/', options: Options(extra: {'refresh': true}));
}
