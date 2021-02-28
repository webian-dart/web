import 'package:web/src/options/request_options.dart';

import 'interceptor.dart';

class RequestInterceptor extends Interceptor {
  final OnRequest _onRequest;

  RequestInterceptor(OnRequest handler) : _onRequest = handler;

  @override
  Future onRequest(RequestOptions options) async => _onRequest(options);
}
