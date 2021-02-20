import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../web.dart';
import 'client_adapters/http_client_adapter.dart';
import 'data/transformer.dart';
import 'fault.dart';
import 'headers.dart';
import 'interceptors/interceptor.dart';
import 'options/options.dart';
import 'requests/cancel_token.dart';
import 'requests/requests.dart';
import 'responses/response.dart';
import 'responses/response_body.dart';
import 'responses/responses.dart';

abstract class WebMixin implements Web {
  /// Default Request config. More see [BaseOptions].
  @override
  late BaseOptions options;

  /// Each Web instance has a interceptor by which you can intercept requests or responses before they are
  /// handled by `then` or `catchError`. the [interceptor] field
  /// contains a [RequestInterceptor] and a [ResponseInterceptor] instance.
  final Interceptors _interceptors = Interceptors();

  @override
  Interceptors get interceptors => _interceptors;

  @override
  late HttpClientAdapter httpClientAdapter;

  @override
  Transformer transformer = DefaultTransformer();

  bool _closed = false;

  @override
  void close({bool force = false}) {
    _closed = true;
    httpClientAdapter.close(force: force);
  }

  /// Handy method to make http GET request, which is a alias of  [BaseWeb.request].
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      queryParameters: queryParameters,
      options: checkOptions('GET', options),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http GET request, which is a alias of [BaseWeb.request].
  @override
  Future<Response<T>> getUri<T>(
    Uri uri, {
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      options: checkOptions('GET', options),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http POST request, which is a alias of  [BaseWeb.request].
  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      data: data,
      options: checkOptions('POST', options),
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Handy method to make http POST request, which is a alias of  [BaseWeb.request].
  @override
  Future<Response<T>> postUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('POST', options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Handy method to make http PUT request, which is a alias of  [BaseWeb.request].
  @override
  Future<Response<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: checkOptions('PUT', options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Handy method to make http PUT request, which is a alias of  [BaseWeb.request].
  @override
  Future<Response<T>> putUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('PUT', options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Handy method to make http HEAD request, which is a alias of [BaseWeb.request].
  @override
  Future<Response<T>> head<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: checkOptions('HEAD', options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http HEAD request, which is a alias of [BaseWeb.request].
  @override
  Future<Response<T>> headUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('HEAD', options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http DELETE request, which is a alias of  [BaseWeb.request].
  @override
  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: checkOptions('DELETE', options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http DELETE request, which is a alias of  [BaseWeb.request].
  @override
  Future<Response<T>> deleteUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('DELETE', options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http PATCH request, which is a alias of  [BaseWeb.request].
  @override
  Future<Response<T>> patch<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: checkOptions('PATCH', options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Handy method to make http PATCH request, which is a alias of  [BaseWeb.request].
  @override
  Future<Response<T>> patchUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('PATCH', options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Assure the final future state is succeed!
  @override
  Future<Response<T>> resolve<T>(response) {
    if (response is! Future) {
      response = Future.value(response);
    }
    return response.then<Response<T>>((data) {
      return assureResponse<T>(data);
    }, onError: (err) {
      // transform 'error' to 'success'
      return assureResponse<T>(err);
    });
  }

  /// Assure the final future state is failed!
  @override
  Future<Response<T>> reject<T>(err) {
    if (err is! Future) {
      err = Future.error(err);
    }
    return err.then<Response<T>>((v) {
      // transform 'success' to 'error'
      throw assureFault(v);
    }, onError: (e) {
      throw assureFault(e);
    });
  }

  /// Lock the current Web instance.
  ///
  /// Web will enqueue the incoming request tasks instead
  /// send them directly when [interceptor.request] is locked.
  @override
  void lock() {
    interceptors.requestLock.lock();
  }

  /// Unlock the current Web instance.
  ///
  /// Web instance dequeue the request task。
  @override
  void unlock() {
    interceptors.requestLock.unlock();
  }

  ///Clear the current Web instance waiting queue.
  @override
  void clear() {
    interceptors.requestLock.clear();
  }

  ///  Download the file and save it in local. The default http method is 'GET',
  ///  you can custom it by [Options.method].
  ///
  ///  [urlPath]: The file url.
  ///
  ///  [savePath]: The path to save the downloading file later. it can be a String or
  ///  a callback:
  ///  1. A path with String type, eg 'xs.jpg'
  ///  2. A callback `String Function(HttpHeaders responseHeaders)`; for example:
  ///  ```dart
  ///   await Web.download(url,(HttpHeaders responseHeaders){
  ///      ...
  ///      return '...';
  ///    });
  ///  ```
  ///
  ///  [onReceiveProgress]: The callback to listen downloading progress.
  ///  please refer to [ProgressCallback].
  ///
  /// [deleteOnError] Whether delete the file when error occurs. The default value is [true].
  ///
  ///  [lengthHeader] : The real size of original file (not compressed).
  ///  When file is compressed:
  ///  1. If this value is 'content-length', the `total` argument of `onProgress` will be -1
  ///  2. If this value is not 'content-length', maybe a custom header indicates the original
  ///  file size , the `total` argument of `onProgress` will be this header value.
  ///
  ///  you can also disable the compression by specifying the 'accept-encoding' header value as '*'
  ///  to assure the value of `total` argument of `onProgress` is not -1. for example:
  ///
  ///     await Web.download(url, './example/flutter.svg',
  ///     options: Options(headers: {HttpHeaders.acceptEncodingHeader: '*'}),  // disable gzip
  ///     onProgress: (received, total) {
  ///       if (total != -1) {
  ///        print((received / total * 100).toStringAsFixed(0) + '%');
  ///       }
  ///     });

  @override
  Future<Response> download(
    String urlPath,
    savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic> queryParameters = const {},
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
  }) async {
    throw UnsupportedError('Unsupport download API in browser');
  }

  ///  Download the file and save it in local. The default http method is 'GET',
  ///  you can custom it by [Options.method].
  ///
  ///  [uri]: The file url.
  ///
  ///  [savePath]: The path to save the downloading file later. it can be a String or
  ///  a callback:
  ///  1. A path with String type, eg 'xs.jpg'
  ///  2. A callback `String Function(HttpHeaders responseHeaders)`; for example:
  ///  ```dart
  ///   await Web.downloadUri(uri,(HttpHeaders responseHeaders){
  ///      ...
  ///      return '...';
  ///    });
  ///  ```
  ///
  ///  [onReceiveProgress]: The callback to listen downloading progress.
  ///  please refer to [ProgressCallback].
  ///
  ///  [lengthHeader] : The real size of original file (not compressed).
  ///  When file is compressed:
  ///  1. If this value is 'content-length', the `total` argument of `onProgress` will be -1
  ///  2. If this value is not 'content-length', maybe a custom header indicates the original
  ///  file size , the `total` argument of `onProgress` will be this header value.
  ///
  ///  you can also disable the compression by specifying the 'accept-encoding' header value as '*'
  ///  to assure the value of `total` argument of `onProgress` is not -1. for example:
  ///
  ///     await Web.downloadUri(uri, './example/flutter.svg',
  ///     options: Options(headers: {HttpHeaders.acceptEncodingHeader: '*'}),  // disable gzip
  ///     onProgress: (received, total) {
  ///       if (total != -1) {
  ///        print((received / total * 100).toStringAsFixed(0) + '%');
  ///       }
  ///     });
  @override
  Future<Response> downloadUri(
    Uri uri,
    savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
  }) {
    return download(
      uri.toString(),
      savePath,
      onReceiveProgress: onReceiveProgress,
      lengthHeader: lengthHeader,
      deleteOnError: deleteOnError,
      cancelToken: cancelToken,
      data: data,
      options: options,
    );
  }

  /// Make http request with options.
  ///
  /// [path] The url path.
  /// [data] The request data
  /// [options] The request options.
  @override
  Future<Response<T>> request<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Make http request with options.
  ///
  /// [uri] The uri.
  /// [data] The request data
  /// [options] The request options.
  @override
  Future<Response<T>> requestUri<T>(
    Uri uri, {
    data,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request(
      uri.toString(),
      data: data,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> _request<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (_closed) {
      throw Fault(error: "Web can't establish new connection after closed.");
    }
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
                  throw assureFault(data, requestOptions);
                }
              });
            }),
          );
        } else {
          return assureResponse(data, requestOptions);
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
            return errInterceptor(assureFault(err, requestOptions)).then((e) {
              if (e is! Response) {
                throw assureFault(e ?? err, requestOptions);
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
    future = future.then(_interceptorWrapper(_dispatchRequest, true));

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
      return assureResponse<T>(data);
    }).catchError((err) {
      if (err == null || _isErrorOrException(err)) {
        throw assureFault(err, requestOptions);
      }
      return assureResponse<T>(err, requestOptions);
    });
  }

  // Initiate Http requests
  Future<Response<T>> _dispatchRequest<T>(RequestOptions options) async {
    var cancelToken = options.cancelToken;
    ResponseBody responseBody;
    try {
      var stream = await _transformData(options);
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
      throw assureFault(e, options);
    }
  }

  // If the request has been cancelled, stop request and throw error.
  void checkCancelled(CancelToken? cancelToken) {
    if (cancelToken != null && cancelToken.cancelError != null) {
      throw cancelToken.cancelError!;
    }
  }

  Future<T> listenCancelForAsyncTask<T>(
      CancelToken? cancelToken, Future<T> future) {
    return Future.any([
      if (cancelToken != null)
        cancelToken.whenCancel.then((e) => throw cancelToken.cancelError!),
      future,
    ]);
  }

  Future<Stream<Uint8List>> _transformData(RequestOptions options) async {
    var data = options.data;
    List<int> bytes;
    Stream<List<int>> stream;
    if (data != null &&
        ['POST', 'PUT', 'PATCH', 'DELETE'].contains(options.method)) {
      // Handle the FormData
      int? length;
      if (data is Stream) {
        assert(data is Stream<List>,
            'Stream type must be `Stream<List>`, but ${data.runtimeType} is found.');
        stream = data as Stream<List<int>>;
        options.headers.keys.any((String key) {
          if (key.toLowerCase() == Headers.contentLengthHeader) {
            length = int.parse(options.headers[key].toString());
            return true;
          }
          return false;
        });
      } else if (data is FormData) {
        if (data is FormData) {
          options.headers[Headers.contentTypeHeader] =
              'multipart/form-data; boundary=${data.boundary}';
        }
        stream = data.finalize();
        length = data.length;
      } else {
        // Call request transformer.
        var _data = await transformer.transformRequest(options);
        if (options.requestEncoder != null) {
          bytes = options.requestEncoder!(_data, options);
        } else {
          //Default convert to utf8
          bytes = utf8.encode(_data);
        }
        // support data sending progress
        length = bytes.length;

        var group = <List<int>>[];
        const size = 1024;
        var groupCount = (bytes.length / size).ceil();
        for (var i = 0; i < groupCount; ++i) {
          var start = i * size;
          group.add(bytes.sublist(start, math.min(start + size, bytes.length)));
        }
        stream = Stream.fromIterable(group);
      }

      if (length != null) {
        options.headers[Headers.contentLengthHeader] = length.toString();
      }
      var complete = 0;
      var byteStream =
          stream.transform<Uint8List>(StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          final cancelToken = options.cancelToken;
          if (cancelToken != null && cancelToken.isCancelled) {
            sink
              ..addError(cancelToken.cancelError!)
              ..close();
          } else {
            sink.add(Uint8List.fromList(data));
            if (length != null) {
              complete += data.length;
              if (options.onSendProgress != null) {
                options.onSendProgress!(complete, length!);
              }
            }
          }
        },
      ));
      if (options.sendTimeout != null && options.sendTimeout! > 0) {
        byteStream.timeout(Duration(milliseconds: options.sendTimeout!),
            onTimeout: (sink) {
          sink.addError(Fault(
            request: options,
            error: 'Sending timeout[${options.connectTimeout}ms]',
            type: FaultType.SEND_TIMEOUT,
          ));
          sink.close();
        });
      }
      return byteStream;
    } else {
      options.headers.remove(Headers.contentTypeHeader);
    }
    return Future.value(Stream.empty());
  }

  RequestOptions mergeOptions(
      Options opt, String url, data, Map<String, dynamic> queryParameters) {
    var query = (Map<String, dynamic>.from(options.queryParameters))
      ..addAll(queryParameters);
    final optBaseUrl = (opt is RequestOptions) ? opt.baseUrl : null;
    final optConnectTimeout =
        (opt is RequestOptions) ? opt.connectTimeout : null;
    return RequestOptions(
      method: (opt.method ?? options.method)?.toUpperCase() ?? 'GET',
      headers: (Map.from(options.headers))..addAll(opt.headers),
      baseUrl: optBaseUrl ?? options.baseUrl,
      path: url,
      data: data,
      connectTimeout: optConnectTimeout ?? options.connectTimeout ?? 0,
      sendTimeout: opt.sendTimeout ?? options.sendTimeout ?? 0,
      receiveTimeout: opt.receiveTimeout ?? options.receiveTimeout ?? 0,
      responseType:
          opt.responseType ?? options.responseType ?? ResponseType.json,
      extra: (Map.from(options.extra))..addAll(opt.extra),
      contentType:
          opt.contentType ?? options.contentType ?? Headers.jsonContentType,
      validateStatus: opt.validateStatus ??
          options.validateStatus ??
          (int? status) {
            return status != null && status >= 200 && status < 300;
          },
      receiveDataWhenStatusError: opt.receiveDataWhenStatusError ??
          (options.receiveDataWhenStatusError ?? true),
      followRedirects: opt.followRedirects ?? (options.followRedirects ?? true),
      maxRedirects: opt.maxRedirects ?? options.maxRedirects ?? 5,
      queryParameters: query,
      requestEncoder: opt.requestEncoder ?? options.requestEncoder,
      responseDecoder: opt.responseDecoder ?? options.responseDecoder,
    );
  }

  Options checkOptions(method, options) {
    options ??= Options();
    options.method = method;
    return options;
  }

  FutureOr checkIfNeedEnqueue(Lock lock, EnqueueCallback callback) {
    if (lock.locked) {
      return lock.enqueue(callback);
    } else {
      return callback();
    }
  }

  Fault assureFault(err, [RequestOptions? requestOptions]) {
    Fault fault;
    if (err is Fault) {
      fault = err;
    } else {
      fault = Fault(error: err);
    }
    fault.request = fault.request ?? requestOptions;
    return fault;
  }

  Response<T> assureResponse<T>(response, [RequestOptions? requestOptions]) {
    if (response is Response<T>) {
      response.request = response.request ?? requestOptions;
    } else if (response is! Response) {
      response = Response<T>(data: response, request: requestOptions);
    } else {
      T data = response.data;
      response = Response<T>(
        data: data,
        headers: response.headers,
        request: response.request,
        statusCode: response.statusCode,
        isRedirect: response.isRedirect,
        redirects: response.redirects,
        statusMessage: response.statusMessage,
      );
    }
    return response;
  }
}
