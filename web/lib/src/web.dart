import 'dart:async';

import 'package:web/src/interceptors/interceptors.dart';

import 'client_adapters/http_client_adapter.dart';
import 'data/transformer.dart';
import 'headers.dart';
import 'instances/instance_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'instances/web_for_browser.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'instances/web_for_native.dart';
import 'options/base_options.dart';
import 'options/options.dart';
import 'requests/cancel_token.dart';
import 'requests/requests.dart';
import 'responses/response.dart';

/// A powerful Http client for Dart, which supports Interceptors,
/// Global configuration, FormData, File downloading etc. and Web is
/// very easy to use.
///
/// You can create a Web instance and config it by two ways:
/// 1. create first , then config it
///
///   ```dart
///    var Web = Web();
///    Web.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
///    Web.options.connectTimeout = 5000; //5s
///    Web.options.receiveTimeout = 5000;
///    Web.options.headers = {HttpHeaders.userAgentHeader: 'Web', 'common-header': 'xx'};
///   ```
/// 2. create and config it:
///
/// ```dart
///   var Web = Web(BaseOptions(
///    baseUrl: "http://www.dtworkroom.com/doris/1/2.0.0/",
///    connectTimeout: 5000,
///    receiveTimeout: 5000,
///    headers: {HttpHeaders.userAgentHeader: 'Web', 'common-header': 'xx'},
///   ));
///  ```

abstract class Web {
  factory Web([BaseOptions? options]) => createWeb(options);

  /// Default Request config. More see [BaseOptions] .
  late BaseOptions options;

  Interceptors get interceptors;

  late HttpClientAdapter httpClientAdapter;

  /// [transformer] allows changes to the request/response data before it is sent/received to/from the server
  /// This is only applicable for request methods 'PUT', 'POST', and 'PATCH'.
  late Transformer transformer;

  /// Shuts down the Web client.
  ///
  /// If [force] is `false` (the default) the [Web] will be kept alive
  /// until all active connections are done. If [force] is `true` any active
  /// connections will be closed to immediately release all resources. These
  /// closed connections will receive an error event to indicate that the client
  /// was shut down. In both cases trying to establish a new connection after
  /// calling [close] will throw an exception.
  void close({bool force = false});

  /// Handy method to make http GET request, which is a alias of  [BaseWeb.request].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http GET request, which is a alias of [BaseWeb.request].
  Future<Response<T>> getUri<T>(
    Uri uri, {
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http POST request, which is a alias of  [BaseWeb.request].
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http POST request, which is a alias of  [BaseWeb.request].
  Future<Response<T>> postUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http PUT request, which is a alias of  [BaseWeb.request].
  Future<Response<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http PUT request, which is a alias of  [BaseWeb.request].
  Future<Response<T>> putUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http HEAD request, which is a alias of [BaseWeb.request].
  Future<Response<T>> head<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http HEAD request, which is a alias of [BaseWeb.request].
  Future<Response<T>> headUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http DELETE request, which is a alias of  [BaseWeb.request].
  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http DELETE request, which is a alias of  [BaseWeb.request].
  Future<Response<T>> deleteUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http PATCH request, which is a alias of  [BaseWeb.request].
  Future<Response<T>> patch<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http PATCH request, which is a alias of  [BaseWeb.request].
  Future<Response<T>> patchUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Assure the final future state is succeed!
  Future<Response<T>> resolve<T>(response);

  /// Assure the final future state is failed!
  Future<Response<T>> reject<T>(err);

  /// Lock the current Web instance.
  ///
  /// Web will enqueue the incoming request tasks instead
  /// send them directly when [interceptor.request] is locked.

  void lock();

  /// Unlock the current Web instance.
  ///
  /// Web instance dequeue the request task。
  void unlock();

  ///Clear the current Web instance waiting queue.

  void clear();

  ///  Download the file and save it in local. The default http method is "GET",
  ///  you can custom it by [Options.method].
  ///
  ///  [urlPath]: The file url.
  ///
  ///  [savePath]: The path to save the downloading file later. it can be a String or
  ///  a callback:
  ///  1. A path with String type, eg "xs.jpg"
  ///  2. A callback `String Function(HttpHeaders responseHeaders)`; for example:
  ///  ```dart
  ///   await Web.download(url,(HttpHeaders responseHeaders){
  ///      ...
  ///      return "...";
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
  ///     await Web.download(url, "./example/flutter.svg",
  ///     options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),  // disable gzip
  ///     onProgress: (received, total) {
  ///       if (total != -1) {
  ///        print((received / total * 100).toStringAsFixed(0) + "%");
  ///       }
  ///     });
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
  });

  ///  Download the file and save it in local. The default http method is "GET",
  ///  you can custom it by [Options.method].
  ///
  ///  [uri]: The file url.
  ///
  ///  [savePath]: The path to save the downloading file later. it can be a String or
  ///  a callback:
  ///  1. A path with String type, eg "xs.jpg"
  ///  2. A callback `String Function(HttpHeaders responseHeaders)`; for example:
  ///  ```dart
  ///   await Web.downloadUri(uri,(HttpHeaders responseHeaders){
  ///      ...
  ///      return "...";
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
  ///     await Web.downloadUri(uri, "./example/flutter.svg",
  ///     options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),  // disable gzip
  ///     onProgress: (received, total) {
  ///       if (total != -1) {
  ///        print((received / total * 100).toStringAsFixed(0) + "%");
  ///       }
  ///     });
  Future<Response> downloadUri(
    Uri uri,
    savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
  });

  /// Make http request with options.
  ///
  /// [path] The url path.
  /// [data] The request data
  /// [options] The request options.

  Future<Response<T>> request<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters = const {},
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Make http request with options.
  ///
  /// [uri] The uri.
  /// [data] The request data
  /// [options] The request options.
  Future<Response<T>> requestUri<T>(
    Uri uri, {
    data,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });
}
