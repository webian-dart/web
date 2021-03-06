import 'package:web/src/headers/header_type.dart';

import '../../Web.dart';
import '../requests/cancel_token.dart';

class RequestOptions extends Options {
  /// Request data, can be any type.
  dynamic data;

  /// Request base url, it can contain sub path, like: 'https://www.google.com/api/'.
  late String baseUrl;

  /// If the `path` starts with 'http(s)', the `baseURL` will be ignored, otherwise,
  /// it will be combined and then resolved with the baseUrl.
  String path = '';

  /// See [Uri.queryParameters]
  Map<String, dynamic> queryParameters;

  CancelToken? cancelToken;

  ProgressCallback? onReceiveProgress;

  ProgressCallback? onSendProgress;

  int? connectTimeout;

  RequestOptions({
    String? method,
    int? sendTimeout,
    int? receiveTimeout,
    this.connectTimeout,
    this.data,
    this.path = '',
    Map<String, dynamic>? queryParameters,
    this.baseUrl = '',
    this.onReceiveProgress,
    this.onSendProgress,
    this.cancelToken,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
  })  : queryParameters = queryParameters ?? {},
        super(
          method: method,
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
          extra: extra,
          headers: headers,
          responseType: responseType,
          contentType: contentType,
          validateStatus: validateStatus,
          receiveDataWhenStatusError: receiveDataWhenStatusError,
          followRedirects: followRedirects,
          maxRedirects: maxRedirects,
          requestEncoder: requestEncoder,
          responseDecoder: responseDecoder,
        );

  /// Create a Option from current instance with merging attributes.
  @override
  RequestOptions merge({
    String? method,
    int? sendTimeout,
    int? receiveTimeout,
    int? connectTimeout,
    String? data,
    String? path,
    Map<String, dynamic>? queryParameters,
    String? baseUrl,
    ProgressCallback? onReceiveProgress,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
  }) {
    return RequestOptions(
      method: method ?? this.method,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      data: data ?? this.data,
      path: path ?? this.path,
      queryParameters: queryParameters ?? this.queryParameters,
      baseUrl: baseUrl ?? this.baseUrl,
      onReceiveProgress: onReceiveProgress ?? this.onReceiveProgress,
      onSendProgress: onSendProgress ?? this.onSendProgress,
      cancelToken: cancelToken ?? this.cancelToken,
      extra: extra ?? Map.from(this.extra),
      headers: headers ?? Map.from(this.headers),
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      requestEncoder: requestEncoder ?? this.requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
    );
  }

  /// generate uri
  Uri get uri {
    var _url = path;
    if (!_url.startsWith(RegExp(r'https?:'))) {
      _url = baseUrl + _url;
      var s = _url.split(':/');
      _url = s[0] + ':/' + s[1].replaceAll('//', '/');
    }
    var query = Transformer.urlEncodeMap(queryParameters);
    if (query.isNotEmpty) {
      _url += (_url.contains('?') ? '&' : '?') + query;
    }
    // Normalize the url.
    return Uri.parse(_url).normalizePath();
  }

  factory RequestOptions.from(
      {required BaseOptions defaultOptions,
      required Options options,
      required String url,
      required data,
      required Map<String, dynamic> queryParameters}) {
    var query = (Map<String, dynamic>.from(defaultOptions.queryParameters))
      ..addAll(queryParameters);
    final optBaseUrl = (options is RequestOptions) ? options.baseUrl : null;
    final optConnectTimeout =
        (options is RequestOptions) ? options.connectTimeout : null;
    return RequestOptions(
      method: (options.method ?? defaultOptions.method)?.toUpperCase() ?? 'GET',
      headers: (Map.from(defaultOptions.headers))..addAll(options.headers),
      baseUrl: optBaseUrl ?? defaultOptions.baseUrl,
      path: url,
      data: data,
      connectTimeout: optConnectTimeout ?? defaultOptions.connectTimeout ?? 0,
      sendTimeout: options.sendTimeout ?? defaultOptions.sendTimeout ?? 0,
      receiveTimeout:
          options.receiveTimeout ?? defaultOptions.receiveTimeout ?? 0,
      responseType: options.responseType ??
          defaultOptions.responseType ??
          ResponseType.json,
      extra: (Map.from(defaultOptions.extra))..addAll(options.extra),
      contentType: options.contentType ??
          defaultOptions.contentType ??
          HeaderType.jsonContent,
      validateStatus: options.validateStatus ??
          defaultOptions.validateStatus ??
          (int? status) {
            return status != null && status >= 200 && status < 300;
          },
      receiveDataWhenStatusError: options.receiveDataWhenStatusError ??
          (defaultOptions.receiveDataWhenStatusError ?? true),
      followRedirects:
          options.followRedirects ?? (defaultOptions.followRedirects ?? true),
      maxRedirects: options.maxRedirects ?? defaultOptions.maxRedirects ?? 5,
      queryParameters: query,
      requestEncoder: options.requestEncoder ?? defaultOptions.requestEncoder,
      responseDecoder:
          options.responseDecoder ?? defaultOptions.responseDecoder,
    );
  }
}

class EmptyRequestOptions extends RequestOptions {}
