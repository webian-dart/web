import 'dart:async';

import 'package:web/src/client_adapters/http_client_adapter.dart';
import 'package:web/src/data/transformer.dart';
import 'package:web/src/faults/fault.dart';
import 'package:web/src/faults/faults_factory.dart';
import 'package:web/src/interceptors/interceptor.dart';
import 'package:web/src/options/request_options.dart';
import 'package:web/src/requests/cancel_token.dart';
import 'package:web/src/requests/request_stream_factory.dart';
import 'package:web/src/responses/response.dart';
import 'package:web/src/responses/response_body.dart';
import 'package:web/src/responses/responses.dart';

import '../headers.dart';

class RequestDispatcher<T> {
  final Interceptors interceptors;
  final HttpClientAdapter httpClientAdapter;
  final Transformer transformer;

  RequestDispatcher(
      {required this.httpClientAdapter,
      required this.transformer,
      required this.interceptors});

  Future<Response<T>> Function(RequestOptions data) get onDispatch =>
      (RequestOptions options) async => await dispatch(options);

  // Initiate Http requests
  Future<Response<T>> dispatch<T>(RequestOptions options) async {
    var cancelToken = options.cancelToken;
    ResponseBody responseBody;
    try {
      var stream = await RequestStreamFactory.build(transformer, options);
      responseBody = await httpClientAdapter.fetch(
        options,
        stream,
        cancelToken?.whenCancel,
      );
      responseBody.headers = responseBody.headers;
      var headers = Headers.fromMap(responseBody.headers);
      var ret = Response(
        headers: headers,
        request: options,
        redirects: responseBody.redirects ?? [],
        isRedirect: responseBody.isRedirect,
        statusCode: responseBody.statusCode,
        statusMessage: responseBody.statusMessage,
        extra: responseBody.extra,
      );
      var statusOk = options.validateStatus!(responseBody.statusCode);
      if (statusOk || options.receiveDataWhenStatusError == true) {
        var forceConvert = !(T == dynamic || T == String) &&
            !(options.responseType == ResponseType.bytes ||
                options.responseType == ResponseType.stream);
        String? contentType;
        if (forceConvert) {
          contentType = headers.value(Headers.contentTypeHeader);
          headers.set(Headers.contentTypeHeader, Headers.jsonContentType);
        }
        ret.data = await transformer.transformResponse(options, responseBody);
        if (forceConvert) {
          headers.set(Headers.contentTypeHeader, contentType);
        }
      } else {
        await responseBody.stream.listen(null).cancel();
      }
      checkCancelled(cancelToken);
      if (statusOk) {
        return checkIfNeedEnqueue(interceptors.responseLock, () => ret)
            as Response<T>;
      } else {
        throw Fault(
          response: ret,
          error: 'Http status error [${responseBody.statusCode}]',
          type: FaultType.RESPONSE,
        );
      }
    } catch (e) {
      throw FaultsFactory.build(e, options);
    }
  }

  // If the request has been cancelled, stop request and throw error.
  void checkCancelled(CancelToken? cancelToken) {
    if (cancelToken != null && cancelToken.cancelError != null) {
      throw cancelToken.cancelError!;
    }
  }

  FutureOr checkIfNeedEnqueue(Lock lock, EnqueueCallback callback) {
    if (lock.locked) {
      return lock.enqueue(callback);
    } else {
      return callback();
    }
  }
}
