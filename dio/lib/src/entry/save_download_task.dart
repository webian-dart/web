import 'dart:async';
import 'dart:io';

import '../../dio.dart';

class SaveDownloadTask {
  final String savePath;
  final String lengthHeader;
  final ProgressCallback? onProgress;
  final CancelToken? cancelToken;
  final bool deleteOnError;
  final Function(dynamic) convertToDioError;

  SaveDownloadTask({
    required this.savePath,
    required this.lengthHeader,
    required this.deleteOnError,
    required this.convertToDioError,
    this.onProgress,
    this.cancelToken,
  });

  Future<Response> start(Response<ResponseBody> response) async {
    final file = _makeFile(savePath, response);

    // Shouldn't call file.writeAsBytesSync(list, flush: flush),
    // because it can write all bytes by once. Consider that the
    // file with a very big size(up 1G), it will be expensive in memory.
    var raf = file.openSync(mode: FileMode.write);

    //Create a Completer to notify the success/error state.
    var completer = Completer<Response>();
    var future = completer.future;
    var received = 0;

    // Stream<Uint8List>
    var stream = response.data!.stream;
    var compressed = false;
    var total = 0;
    var contentEncoding = response.headers.value(Headers.contentEncodingHeader);
    if (contentEncoding != null) {
      compressed = ['gzip', 'deflate', 'compress'].contains(contentEncoding);
    }
    if (lengthHeader == Headers.contentLengthHeader && compressed) {
      total = -1;
    } else {
      total = int.parse(response.headers.value(lengthHeader) ?? '-1');
    }

    late StreamSubscription subscription;
    Future? asyncWrite;
    var closed = false;
    Future _closeAndDelete() async {
      if (!closed) {
        closed = true;
        await asyncWrite;
        await raf.close();
        if (deleteOnError) await file.delete();
      }
    }

    subscription = stream.listen(
      (data) {
        subscription.pause();
        // Write file asynchronously
        asyncWrite = raf.writeFrom(data).then((_raf) {
          // Notify progress
          received += data.length;
          onProgress?.call(received, total);
          raf = _raf;
          if (cancelToken?.isCancelled == false) {
            subscription.resume();
          }
        }).catchError((err) async {
          try {
            await subscription.cancel();
          } finally {
            completer.completeError(convertToDioError(err));
          }
        });
      },
      onDone: () async {
        try {
          await asyncWrite;
          closed = true;
          await raf.close();
          completer.complete(response);
        } catch (e) {
          completer.completeError(convertToDioError(e));
        }
      },
      onError: (e) async {
        try {
          await _closeAndDelete();
        } finally {
          completer.completeError(convertToDioError(e));
        }
      },
      cancelOnError: true,
    );
    // ignore: unawaited_futures
    cancelToken?.whenCancel.then((_) async {
      await subscription.cancel();
      await _closeAndDelete();
    });

    if ((response.request?.receiveTimeout ?? 0) > 0) {
      future = future
          .timeout(
              Duration(milliseconds: response.request?.receiveTimeout ?? 0))
          .catchError((err) async {
        await subscription.cancel();
        await _closeAndDelete();
        if (err is TimeoutException) {
          throw DioError(
            request: response.request,
            error:
                'Receiving data timeout[${response.request?.receiveTimeout}ms]',
            type: DioErrorType.RECEIVE_TIMEOUT,
          );
        } else {
          throw err;
        }
      });
    }
    return future;
  }

  File _makeFile(dynamic savePath, Response<ResponseBody> response) {
    File file;
    if (savePath is Function) {
      assert(savePath is String Function(Headers),
          'savePath callback type must be `String Function(HttpHeaders)`');
      file = File(savePath(response.headers));
    } else {
      file = File(savePath.toString());
    }
    //If directory (or file) doesn't exist yet, the entire method fails
    return file..createSync(recursive: true);
  }
}
