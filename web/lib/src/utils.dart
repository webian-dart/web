import 'dart:async';
import 'dart:convert';

/// A regular expression that matches strings that are composed entirely of
/// ASCII-compatible characters.
final RegExp _asciiOnly = RegExp(r'^[\x00-\x7F]+$');

/// Returns whether [string] is composed entirely of ASCII-compatible
/// characters.
bool isPlainAscii(String string) => _asciiOnly.hasMatch(string);

/// Pipes all data and errors from [stream] into [sink]. Completes [Future] once
/// [stream] is done. Unlike [store], [sink] remains open after [stream] is
/// done.
Future writeStreamToSink(Stream stream, EventSink sink) {
  var completer = Completer();
  stream.listen(sink.add,
      onError: sink.addError, onDone: () => completer.complete());
  return completer.future;
}

/// Returns the [Encoding] that corresponds to [charset]. Returns [fallback] if
/// [charset] is null or if no [Encoding] was found that corresponds to
/// [charset].
Encoding encodingForCharset(String? charset, [Encoding fallback = latin1]) {
  if (charset == null) return fallback;
  var encoding = Encoding.getByName(charset);
  return encoding ?? fallback;
}
