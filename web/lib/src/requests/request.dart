import 'dart:async';

import 'package:web/src/interceptors/interceptors.dart';

import '../../web.dart';
import '../faults/faults_factory.dart';
import '../interceptors/interceptors_wrapper.dart';
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
    final requestOptions = makeRequestOptions(
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
    // Start the request flow
    var future = Future<dynamic>.value(requestOptions);
    // Build a request flow in which the processors(interceptors)
    // execute in FIFO order.
    future = _setupInterceptors(future, requestOptions, cancelToken);
    // Normalize errors, we convert error to the Fault
    return future
        .then<Response<T>>((data) => ResponseFactory.build<T>(data))
        .catchError(
      (err) {
        if (err == null || isErrorOrException(err)) {
          throw FaultsFactory.build(err, requestOptions);
        }
        return ResponseFactory.build<T>(err, requestOptions);
      },
    );
  }

  Future _setupInterceptors(
      Future future, RequestOptions requestOptions, CancelToken? cancelToken) {
    final interceptorWrapper = InterceptorsWrapper(
        cancelToken: cancelToken,
        interceptors: interceptors,
        requestOptions: requestOptions);

    // Add request interceptors to request flow
    interceptors.forEach((Interceptor interceptor) {
      future =
          future.then(interceptorWrapper.wrapForRequest(interceptor.onRequest));
    });

    // Add dispatching callback to request flow
    final dispatcher = RequestDispatcher(
        httpClientAdapter: httpClientAdapter,
        transformer: transformer,
        interceptors: interceptors);
    future =
        future.then(interceptorWrapper.wrapForRequest(dispatcher.onDispatch));

    // Add response interceptors to request flow
    interceptors.forEach((Interceptor interceptor) {
      future = future
          .then(interceptorWrapper.wrapForResponse(interceptor.onResponse));
    });

    // Add error handlers to request flow
    interceptors.forEach((Interceptor interceptor) {
      future = future.catchError(
          interceptorWrapper.makeOnErrorHandler(interceptor.onFault));
    });
    return future;
  }

  RequestOptions makeRequestOptions({
    required data,
    required Map<String, dynamic> queryParameters,
    required CancelToken? cancelToken,
    required Options? options,
    required ProgressCallback? onSendProgress,
    required ProgressCallback? onReceiveProgress,
  }) {
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
    return RequestOptions.from(
        defaultOptions: defaultOptions,
        options: options,
        url: path,
        data: data,
        queryParameters: queryParameters)
      ..onReceiveProgress = onReceiveProgress
      ..onSendProgress = onSendProgress
      ..cancelToken = cancelToken
      ..setupResponseType<T>();
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

extension on RequestOptions {
  void setupResponseType<T>() {
    if (shouldSetType<T>()) {
      if (T == String) {
        responseType = ResponseType.plain;
      } else {
        responseType = ResponseType.json;
      }
    }
  }

  bool shouldSetType<T>() =>
      T != dynamic &&
      !(responseType == ResponseType.bytes ||
          responseType == ResponseType.stream);
}
