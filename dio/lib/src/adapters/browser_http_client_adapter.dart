import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import '../adapter.dart';
import '../dio_error.dart';
import '../headers.dart';
import '../options.dart';

HttpClientAdapter createAdapter() => BrowserHttpClientAdapter();

class BrowserHttpClientAdapter implements HttpClientAdapter {
  /// These are aborted if the client is closed.
  final _xhrs = <HttpRequest>[];

  /// Whether to send credentials such as cookies or authorization headers for
  /// cross-site requests.
  ///
  /// Defaults to `false`.
  ///
  /// You can also override this value in Options.extra['withCredentials'] for each request
  bool withCredentials = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future? cancelFuture) {
    final xhr = HttpRequest();
    final completer = Completer<ResponseBody>();
    _xhrs.add(xhr);
    _setupRequest(xhr, options);
    _setupHandlers(xhr,
        completer: completer, options: options, cancelFuture: cancelFuture);
    _start(xhr, requestStream);
    return completer.future.whenComplete(() => _xhrs.remove(xhr));
  }

  void _setupHandlers(HttpRequest xhr,
      {required Completer<ResponseBody> completer,
      required RequestOptions options,
      required Future? cancelFuture}) {
    xhr.onLoad.first
        .then((_) => _onResponse(xhr, completer: completer, options: options));

    xhr.onError.first.then((_) {
      // Unfortunately, the underlying XMLHttpRequest API doesn't expose any
      // specific information about the error itself.
      _onError('XMLHttpRequest error.', options: options, completer: completer);
    });
    cancelFuture?.then((_) => _cancelFuture(xhr));
  }

  void _setupRequest(HttpRequest xhr, RequestOptions options) {
    xhr
      ..open(options.method!, options.uri.toString(), async: true)
      ..responseType = 'blob'
      ..withCredentials = options.extra['withCredentials'] ?? withCredentials;
    options.headers.remove(Headers.contentLengthHeader);
    options.headers.forEach((key, v) => xhr.setRequestHeader(key, '$v'));
  }

  void _start(HttpRequest xhr, Stream<List<int>>? requestStream) {
    if (requestStream == null) {
      xhr.send();
    } else {
      requestStream
          .reduce((a, b) => Uint8List.fromList([...a, ...b]))
          .then(xhr.send);
    }
  }

  void _cancelFuture(HttpRequest xhr) {
    if (xhr.readyState < 4 && xhr.readyState > 0) {
      try {
        xhr.abort();
      } catch (e) {
        // ignore
      }
    }
  }

  void _onResponse(HttpRequest xhr,
      {required Completer<ResponseBody> completer,
      required RequestOptions options}) {
    // TODO: Set the response type to "arraybuffer" when issue 18542 is fixed.
    var blob = xhr.response ?? Blob([]);
    var reader = FileReader();

    reader.onLoad.first.then((_) {
      var body = reader.result as Uint8List;
      completer.complete(
        ResponseBody.fromBytes(
          body,
          xhr.status,
          headers: xhr.responseHeaders.map((k, v) => MapEntry(k, v.split(','))),
          statusMessage: xhr.statusText,
          isRedirect: xhr.status == 302 || xhr.status == 301,
        ),
      );
    });

    reader.onError.first.then(
        (error) => _onError(error, options: options, completer: completer));
    reader.readAsArrayBuffer(blob);
  }

  /// Closes the client.
  ///
  /// This terminates all active requests.
  @override
  void close({bool force = false}) {
    if (force) {
      for (var xhr in _xhrs) {
        xhr.abort();
      }
    }
    _xhrs.clear();
  }

  void _onError(dynamic error,
      {required Completer<ResponseBody> completer,
      required RequestOptions options}) {
    completer.completeError(
      DioError(
        type: DioErrorType.RESPONSE,
        error: error,
        request: options,
      ),
      StackTrace.current,
    );
  }
}
