import 'package:web/src/responses/response.dart';

import 'interceptor.dart';

class ResponseInterceptor extends Interceptor {
  final OnResponse _onResponse;

  ResponseInterceptor(OnResponse handler) : _onResponse = handler;

  Future onResponse(Response response) async => _onResponse(response);
}
