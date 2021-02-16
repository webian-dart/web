import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../adapter.dart';
import '../dio_error.dart';
import '../options.dart';
import '../redirect_record.dart';

typedef OnHttpClientCreate = dynamic Function(HttpClient client);

HttpClientAdapter createAdapter() => DefaultHttpClientAdapter();

/// The default HttpClientAdapter for Dio.
class DefaultHttpClientAdapter implements HttpClientAdapter {
  /// [Dio] will create HttpClient when it is needed.
  /// If [onHttpClientCreate] is provided, [Dio] will call
  /// it when a HttpClient created.
  OnHttpClientCreate? onHttpClientCreate;

  HttpClient? _defaultHttpClient;

  bool _closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    _verifyNotClosed();
    final _httpClient = _configHttpClient(cancelFuture, options.connectTimeout);
    final request = await _openConnection(_httpClient, options);
    await _addStream(request, stream: requestStream, options: options);
    final future = _closeRequest(request, options);
    late HttpClientResponse responseStream;
    try {
      responseStream = await future;
    } on TimeoutException {
      _throwConnectingTimeout(options);
    }
    return _buildResponseBody(responseStream);
  }

  Future _closeRequest(HttpClientRequest request, RequestOptions options) {
    Future future = request.close();
    if ((options.connectTimeout ?? -1) > 0) {
      future = future.timeout(Duration(milliseconds: options.connectTimeout!));
    }
    return future;
  }

  Future _addStream(HttpClientRequest request,
      {required Stream<List<int>>? stream,
      required RequestOptions options}) async {
    if (options.method != 'GET' && stream != null) {
      // Transform the request data
      await request.addStream(stream);
    }
  }

  void _verifyNotClosed() {
    if (_closed) {
      throw Exception(
          "Can't establish connection after [HttpClientAdapter] closed!");
    }
  }

  ResponseBody _buildResponseBody(HttpClientResponse responseStream) {
    // https://github.com/dart-lang/co19/issues/383
    final stream =
        responseStream.transform<Uint8List>(StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        sink.add(Uint8List.fromList(data));
      },
    ));
    return ResponseBody(
      stream,
      responseStream.statusCode,
      headers: responseStream.copyHeaders(),
      isRedirect: responseStream.hasRedirects(),
      redirects: responseStream.redirectRecords,
      statusMessage: responseStream.reasonPhrase,
    );
  }

  Future<HttpClientRequest> _openConnection(
      HttpClient httpClient, RequestOptions options) async {
    Future requestFuture = httpClient.openUrl(options.method!, options.uri);
    HttpClientRequest request;
    try {
      request = await requestFuture;
      //Set Headers
      options.headers.forEach((k, v) => request.headers.set(k, v));
    } on SocketException catch (e) {
      if (e.message.contains('timed out')) _throwConnectingTimeout(options);
      rethrow;
    }
    request.followRedirects = options.followRedirects ?? true;
    request.maxRedirects = options.maxRedirects ?? 5;
    return request;
  }

  HttpClient _configHttpClient(Future? cancelFuture, int? connectionTimeout) {
    var _connectionTimeout = connectionTimeout.asDuration;
    if (cancelFuture != null) {
      return _configWithCancelFuture(cancelFuture, _connectionTimeout);
    }
    if (_defaultHttpClient == null) _buildDefault(_connectionTimeout);
    return _defaultHttpClient!;
  }

  void _buildDefault(Duration? connectionTimeout) {
    var client = HttpClient()
      ..idleTimeout = Duration(seconds: 3)
      ..connectionTimeout = connectionTimeout;
    //user can return a HttpClient instance
    _defaultHttpClient = onHttpClientCreate?.call(client) ?? client;
  }

  HttpClient _configWithCancelFuture(
      Future cancelFuture, Duration? connectionTimeout) {
    var client = HttpClient()..userAgent = null;
    //user can return a HttpClient instance
    client = (onHttpClientCreate?.call(client) ?? client)
      ..idleTimeout = Duration(seconds: 0);
    cancelFuture.whenComplete(() => _closeAfterCancel(client));
    return client..connectionTimeout = connectionTimeout;
  }

  void _closeAfterCancel(HttpClient client) {
    Future.delayed(Duration(seconds: 0)).then((e) {
      try {
        client.close(force: true);
      } catch (e) {
        //...
      }
    });
  }

  @override
  void close({bool force = false}) {
    _closed = _closed;
    _defaultHttpClient?.close(force: force);
  }

  void _throwConnectingTimeout(RequestOptions options) {
    throw DioError(
      request: options,
      error: 'Connecting timed out [${options.connectTimeout}ms]',
      type: DioErrorType.CONNECT_TIMEOUT,
    );
  }
}

extension on HttpClientResponse {
  bool hasRedirects() => isRedirect || redirects.isNotEmpty;

  List<RedirectRecord> get redirectRecords => redirects
      .map((e) => RedirectRecord(e.statusCode, e.method, e.location))
      .toList();

  Map<String, List<String>> copyHeaders() {
    final map = <String, List<String>>{};
    headers.forEach((key, values) {
      map[key] = values;
    });
    return map;
  }
}

extension on int? {
  Duration? get asDuration =>
      ((this ?? -1) > 0) ? Duration(milliseconds: this ?? -1) : null;
}
