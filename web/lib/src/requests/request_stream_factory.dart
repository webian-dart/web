import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/src/data/form_data.dart';
import 'package:web/src/data/transformer.dart';
import 'package:web/src/faults/fault.dart';
import 'package:web/src/options/request_options.dart';

import '../headers.dart';

class RequestStreamFactory {
  static Future<Stream<Uint8List>> build(
      Transformer transformer, RequestOptions options) async {
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
}
