import 'dart:async';

import 'package:web/src/headers/header_type.dart';
import 'package:web/src/requests/request.dart';

import '../../web.dart';
import '../client_adapters/default_http_client_adapter.dart';
import '../faults/fault.dart';
import '../headers/headers.dart';
import '../options/options.dart';
import '../requests/cancel_token.dart';
import '../requests/requests.dart';
import '../responses/response.dart';
import '../responses/response_body.dart';
import '../web_mixin.dart';
import 'save_download_task.dart';

Web createWeb([BaseOptions? options]) => WebForNative(options);

class WebForNative with WebMixin implements Web {
  /// Create Web instance with default [Options].
  /// It's mostly just one Web instance in your application.
  WebForNative([BaseOptions? options]) {
    this.options = options ?? BaseOptions();
    httpClientAdapter = DefaultHttpClientAdapter();
  }

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
  ///   await Web.download(url,(Headers responseHeaders){
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
  @override
  Future<Response> download(
    String urlPath,
    savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic> queryParameters = const {},
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = HeaderType.contentLength,
    data,
    Options? options,
  }) async {
    // We set the `responseType` to [ResponseType.STREAM] to retrieve the
    // response stream.
    options ??= checkOptions('GET', options);

    // Receive data with stream.
    options.responseType = ResponseType.stream;

    final response = await _makeRequest(urlPath,
        data: data,
        options: options,
        queryParameters: queryParameters,
        cancelToken: cancelToken);
    final future = SaveDownloadTask(
            savePath: savePath,
            lengthHeader: lengthHeader,
            onProgress: onReceiveProgress,
            deleteOnError: deleteOnError)
        .start(response);
    return Request.listenCancelForAsyncTask(cancelToken, future);
  }

  Future<Response<ResponseBody>> _makeRequest(String urlPath,
      {required Map<String, dynamic> queryParameters,
      dynamic data,
      Options? options,
      CancelToken? cancelToken}) async {
    try {
      final res = await request<ResponseBody>(
        urlPath,
        data: data,
        options: options,
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? CancelToken(),
      );
      return res..headers = Headers.fromMap(res.data?.headers ?? const {});
    } on Fault catch (e) {
      await _onFault(e);
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future _onFault(Fault error) async {
    if (error.type == FaultType.RESPONSE) {
      if (error.response?.request?.receiveDataWhenStatusError == true) {
        var options = (error.response?.request ?? EmptyRequestOptions())
          ..responseType = ResponseType.json;
        var res = await transformer.transformResponse(
          options,
          error.response?.data,
        );
        error.response?.data = res;
      } else {
        error.response?.data = null;
      }
    }
    throw error;
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
  ///   await Web.downloadUri(uri,(Headers responseHeaders){
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
    lengthHeader = HeaderType.contentLength,
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
}
