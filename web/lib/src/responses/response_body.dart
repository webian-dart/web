import 'dart:convert';
import 'dart:typed_data';

import '../requests/redirect_record.dart';

class ResponseBody {
  ResponseBody(
    this.stream,
    this.statusCode, {
    this.headers = const {},
    this.statusMessage,
    this.isRedirect = false,
    this.redirects,
  });

  /// The response stream
  Stream<Uint8List> stream;

  /// the response headers
  late Map<String, List<String>> headers;

  /// Http status code
  int? statusCode;

  /// Returns the reason phrase associated with the status code.
  /// The reason phrase must be set before the body is written
  /// to. Setting the reason phrase after writing to the body.
  String? statusMessage;

  /// Whether this response is a redirect.
  final bool isRedirect;

  List<RedirectRecord>? redirects;

  Map<String, dynamic> extra = {};

  ResponseBody.fromString(
    String text,
    this.statusCode, {
    this.headers = const {},
    this.statusMessage,
    this.isRedirect = false,
  }) : stream = Stream.fromIterable(
            utf8.encode(text).map((e) => Uint8List.fromList([e])).toList());

  ResponseBody.fromBytes(
    List<int> bytes,
    this.statusCode, {
    this.headers = const {},
    this.statusMessage,
    this.isRedirect = false,
  }) : stream = Stream.fromIterable(
            bytes.map((e) => Uint8List.fromList([e])).toList());
}
