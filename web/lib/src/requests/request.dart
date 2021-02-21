import 'dart:async';

import '../../web.dart';
import '../faults/faults_factory.dart';
import '../headers.dart';
import '../interceptors/interceptor_wrapper.dart';
import '../options/base_options.dart';
import '../options/options.dart';
import '../options/request_options.dart';
import '../responses/response.dart';
import '../responses/response_factory.dart';
import '../responses/responses.dart';
import 'cancel_token.dart';
import 'request_dispatcher.dart';
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

    final interceptorWrapper = InterceptorWrapper(
        cancelToken: cancelToken,
        interceptors: interceptors,
        requestOptions: requestOptions);

    // Build a request flow in which the processors(interceptors)
    // execute in FIFO order.

    // Start the request flow
    late Future future;
    future = Future.value(requestOptions);
    // Add request interceptors to request flow
    interceptors.forEach((Interceptor interceptor) {
      future =
          future.then(interceptorWrapper.handle(interceptor.onRequest, true));
    });

    // Add dispatching callback to request flow
    final dispatcher = RequestDispatcher(
        httpClientAdapter: httpClientAdapter,
        transformer: transformer,
        interceptors: interceptors);
    future =
        future.then(interceptorWrapper.handle(dispatcher.onDispatch, true));

    // Add response interceptors to request flow
    interceptors.forEach((Interceptor interceptor) {
      future =
          future.then(interceptorWrapper.handle(interceptor.onResponse, false));
    });

    // Add error handlers to request flow
    interceptors.forEach((Interceptor interceptor) {
      future = future
          .catchError(interceptorWrapper.handleError(interceptor.onError));
    });

    // Normalize errors, we convert error to the Fault
    return future.then<Response<T>>((data) {
      return ResponseFactory.build<T>(data);
    }).catchError((err) {
      if (err == null || isErrorOrException(err)) {
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

  static bool isErrorOrException(t) => t is Exception || t is Error;
}
