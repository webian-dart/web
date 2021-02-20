import 'dart:async';

import '../headers.dart';
import '../options/base_options.dart';
import '../options/options.dart';
import '../options/request_options.dart';
import '../responses/response.dart';
import '../responses/responses.dart';
import 'cancel_token.dart';
import 'requests.dart';

class Request<T> {
  final String path;
  final BaseOptions defaultOptions;
  // CancelToken? _cancelToken;
  // Map<String, dynamic>? _queryParameters;
  // dynamic? _data;
  // ProgressCallback? _onSendProgress;
  // ProgressCallback? _onReceiveProgress;
  // Options? options;

  Request(
    this.path, {
    required this.defaultOptions,
    //   Map<String, dynamic>? queryParameters = const {},
    //   dynamic? data,
    //   ProgressCallback? onSendProgress,
    //   ProgressCallback? onReceiveProgress,
    //   CancelToken? cancelToken,
  });
  // : _queryParameters = queryParameters,
  //   _data = data;

  Future<Response<T>> execute({
    data,
    Map<String, dynamic> queryParameters = const {},
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    options ??= Options();
    if (options is RequestOptions) {
      data = data ?? options.data;
      queryParameters = queryParameters.isNotEmpty
          ? queryParameters
          : options.queryParameters;
      cancelToken = cancelToken ?? options.cancelToken;
      onSendProgress = onSendProgress ?? options.onSendProgress;
      onReceiveProgress = onReceiveProgress ?? options.onReceiveProgress;
    }
    var requestOptions = mergeOptions(options, path, data, queryParameters);
    requestOptions.onReceiveProgress = onReceiveProgress;
    requestOptions.onSendProgress = onSendProgress;
    requestOptions.cancelToken = cancelToken;
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }

    bool _isErrorOrException(t) => t is Exception || t is Error;

    return Future.error({});

    // // Convert the request/response interceptor to a functional callback in which
    // // we can handle the return value of interceptor callback.
    // FutureOr<dynamic> Function(dynamic) _interceptorWrapper(
    //     interceptor, bool request) {
    //   return (data) async {
    //     var type = request ? (data is RequestOptions) : (data is Response);
    //     var lock =
    //     request ? interceptors.requestLock : interceptors.responseLock;
    //     if (_isErrorOrException(data) || type) {
    //       return listenCancelForAsyncTask(
    //         cancelToken,
    //         Future(() {
    //           return checkIfNeedEnqueue(lock, () {
    //             if (type) {
    //               if (!request) data.request = data.request ?? requestOptions;
    //               return interceptor(data).then((e) => e ?? data);
    //             } else {
    //               throw assureFault(data, requestOptions);
    //             }
    //           });
    //         }),
    //       );
    //     } else {
    //       return assureResponse(data, requestOptions);
    //     }
    //   };
    // }
    //
    // // Convert the error interceptor to a functional callback in which
    // // we can handle the return value of interceptor callback.
    // FutureOr<dynamic> Function(dynamic) _errorInterceptorWrapper(
    //     errInterceptor) {
    //   return (err) {
    //     return checkIfNeedEnqueue(interceptors.errorLock, () {
    //       if (err is! Response) {
    //         return errInterceptor(assureFault(err, requestOptions))
    //             .then((e) {
    //           if (e is! Response) {
    //             throw assureFault(e ?? err, requestOptions);
    //           }
    //           return e;
    //         });
    //       }
    //       // err is a Response instance
    //       return err;
    //     });
    //   };
    // }
    //
    // // Build a request flow in which the processors(interceptors)
    // // execute in FIFO order.
    //
    // // Start the request flow
    // late Future future;
    // future = Future.value(requestOptions);
    // // Add request interceptors to request flow
    // interceptors.forEach((Interceptor interceptor) {
    //   future = future.then(_interceptorWrapper(interceptor.onRequest, true));
    // });
    //
    // // Add dispatching callback to request flow
    // future = future.then(_interceptorWrapper(_dispatchRequest, true));
    //
    // // Add response interceptors to request flow
    // interceptors.forEach((Interceptor interceptor) {
    //   future = future.then(_interceptorWrapper(interceptor.onResponse, false));
    // });
    //
    // // Add error handlers to request flow
    // interceptors.forEach((Interceptor interceptor) {
    //   future = future.catchError(_errorInterceptorWrapper(interceptor.onError));
    // });
    //
    // // Normalize errors, we convert error to the Fault
    // return future.then<Response<T>>((data) {
    //   return assureResponse<T>(data);
    // }).catchError((err) {
    //   if (err == null || _isErrorOrException(err)) {
    //     throw assureFault(err, requestOptions);
    //   }
    //   return assureResponse<T>(err, requestOptions);
    // });
    // }
  }

  RequestOptions mergeOptions(
      Options opt, String url, data, Map<String, dynamic> queryParameters) {
    var query = (Map<String, dynamic>.from(defaultOptions.queryParameters))
      ..addAll(queryParameters);
    final optBaseUrl = (opt is RequestOptions) ? opt.baseUrl : null;
    final optConnectTimeout =
        (opt is RequestOptions) ? opt.connectTimeout : null;
    return RequestOptions(
      method: (opt.method ?? defaultOptions.method)?.toUpperCase() ?? 'GET',
      headers: (Map.from(defaultOptions.headers))..addAll(opt.headers),
      baseUrl: optBaseUrl ?? defaultOptions.baseUrl,
      path: url,
      data: data,
      connectTimeout: optConnectTimeout ?? defaultOptions.connectTimeout ?? 0,
      sendTimeout: opt.sendTimeout ?? defaultOptions.sendTimeout ?? 0,
      receiveTimeout: opt.receiveTimeout ?? defaultOptions.receiveTimeout ?? 0,
      responseType:
          opt.responseType ?? defaultOptions.responseType ?? ResponseType.json,
      extra: (Map.from(defaultOptions.extra))..addAll(opt.extra),
      contentType: opt.contentType ??
          defaultOptions.contentType ??
          Headers.jsonContentType,
      validateStatus: opt.validateStatus ??
          defaultOptions.validateStatus ??
          (int? status) {
            return status != null && status >= 200 && status < 300;
          },
      receiveDataWhenStatusError: opt.receiveDataWhenStatusError ??
          (defaultOptions.receiveDataWhenStatusError ?? true),
      followRedirects:
          opt.followRedirects ?? (defaultOptions.followRedirects ?? true),
      maxRedirects: opt.maxRedirects ?? defaultOptions.maxRedirects ?? 5,
      queryParameters: query,
      requestEncoder: opt.requestEncoder ?? defaultOptions.requestEncoder,
      responseDecoder: opt.responseDecoder ?? defaultOptions.responseDecoder,
    );
  }
}
