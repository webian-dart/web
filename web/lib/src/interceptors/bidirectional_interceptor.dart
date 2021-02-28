import 'package:web/src/faults/fault.dart';
import 'package:web/src/options/request_options.dart';
import 'package:web/src/responses/response.dart';

import 'interceptor.dart';

class BiDirectionalInterceptor extends Interceptor {
  final OnRequest _onRequest;
  final OnResponse _onResponse;
  final OnFault _onFault;

  BiDirectionalInterceptor({
    required OnRequest onRequest,
    required OnResponse onResponse,
    required OnFault onFault,
  })   : _onRequest = onRequest,
        _onResponse = onResponse,
        _onFault = onFault;

  @override
  Future onRequest(RequestOptions options) async => _onRequest.call(options);

  @override
  Future onResponse(Response response) async => _onResponse.call(response);

  @override
  Future onFault(Fault fault) async => _onFault.call(fault);
}
