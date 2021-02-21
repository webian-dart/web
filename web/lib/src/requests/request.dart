import 'dart:async';

import 'package:web/src/faults/faults_factory.dart';
import 'package:web/src/requests/request_dispatcher.dart';
import 'package:web/src/requests/request_stream_factory.dart';
import 'package:web/src/responses/response_factory.dart';

import '../../web.dart';
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
  final Interceptors interceptors;
  final HttpClientAdapter httpClientAdapter;
  final Transformer transformer;

  Request(this.path,
      {required this.httpClientAdapter,
      required this.transformer,
      required this.defaultOptions,
      required this.interceptors});

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

    // Convert the request/response interceptor to a functional callback in which
    // we can handle the return value of interceptor callback.
    FutureOr<dynamic> Function(dynamic) _interceptorWrapper(
        interceptor, bool request) {
      return (data) async {
        var type = request ? (data is RequestOptions) : (data is Response);
        var lock =
            request ? interceptors.requestLock : interceptors.responseLock;
        if (_isErrorOrException(data) || type) {
          return listenCancelForAsyncTask(
            cancelToken,
            Future(() {
              return checkIfNeedEnqueue(lock, () {
                if (type) {
                  if (!request) data.request = data.request ?? requestOptions;
                  return interceptor(data).then((e) => e ?? data);
                } else {
                  throw FaultsFactory.build(data, requestOptions);
                }
              });
            }),
          );
        } else {
          return ResponseFactory.build(data, requestOptions);
        }
      };
    }

    // Convert the error interceptor to a functional callback in which
    // we can handle the return value of interceptor callback.
    FutureOr<dynamic> Function(dynamic) _errorInterceptorWrapper(
        errInterceptor) {
      return (err) {
        return checkIfNeedEnqueue(interceptors.errorLock, () {
          if (err is! Response) {
            return errInterceptor(FaultsFactory.build(err, requestOptions))
                .then((e) {
              if (e is! Response) {
                throw FaultsFactory.build(e ?? err, requestOptions);
              }
              return e;
            });
          }
          // err is a Response instance
          return err;
        });
      };
    }

    // Build a request flow in which the processors(interceptors)
    // execute in FIFO order.

    // Start the request flow
    late Future future;
    future = Future.value(requestOptions);
    // Add request interceptors to request flow
    interceptors.forEach((Interceptor interceptor) {
      future = future.then(_interceptorWrapper(interceptor.onRequest, true));
    });

    // Add dispatching callback to request flow
    final dispatcher = RequestDispatcher(
        httpClientAdapter: httpClientAdapter,
        transformer: transformer,
        interceptors: interceptors);
    future = future.then(_interceptorWrapper(dispatcher.onDispatch, true));

    // Add response interceptors to request flow
    interceptors.forEach((Interceptor interceptor) {
      future = future.then(_interceptorWrapper(interceptor.onResponse, false));
    });

    // Add error handlers to request flow
    interceptors.forEach((Interceptor interceptor) {
      future = future.catchError(_errorInterceptorWrapper(interceptor.onError));
    });

    // Normalize errors, we convert error to the Fault
    return future.then<Response<T>>((data) {
      return ResponseFactory.build<T>(data);
    }).catchError((err) {
      if (err == null || _isErrorOrException(err)) {
        throw FaultsFactory.build(err, requestOptions);
      }
      return ResponseFactory.build<T>(err, requestOptions);
    });
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

  FutureOr checkIfNeedEnqueue(Lock lock, EnqueueCallback callback) {
    if (lock.locked) {
      return lock.enqueue(callback);
    } else {
      return callback();
    }
  }

  // Initiate Http requests
  Future<Response<T>> _dispatchRequest<T>(RequestOptions options) async {
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

  static Future<T> listenCancelForAsyncTask<T>(
      CancelToken? cancelToken, Future<T> future) {
    return Future.any([
      if (cancelToken != null)
        cancelToken.whenCancel.then((e) => throw cancelToken.cancelError!),
      future,
    ]);
  }
}
