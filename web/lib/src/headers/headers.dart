import 'package:web/src/extensions/map_extensions.dart';

typedef HeaderForEachCallback = void Function(String name, List<String> values);

class Headers {
  final Map<String, List<String>> _map;

  Map<String, List<String>> get map => _map;

  Headers() : _map = toCaseInsensitiveKeyMap<List<String>>({});

  Headers.fromMap(Map<String, List<String>> map)
      : _map = toCaseInsensitiveKeyMap(
            map.map((k, v) => MapEntry(k.trim().toLowerCase(), v)));

  /// Returns the list of values for the header named [name]. If there
  /// is no header with the provided name, [:null:] will be returned.
  List<String>? operator [](String name) {
    return _map[name.trim().toLowerCase()];
  }

  /// Convenience method for the value for a single valued header. If
  /// there is no header with the provided name, [:null:] will be
  /// returned. If the header has more than one value an exception is
  /// thrown.
  String? valueOf(String name) {
    final values = this[name];
    if (values == null) return null;
    if (values.length == 1) return values.first;
    throw Exception(
        '"$name" header has more than one value, please use Headers[name]');
  }

  /// Adds a header value. The header named [name] will have the value
  /// [value] added to its list of values.
  void add(String name, String value) {
    var values = this[name];
    if (values == null) {
      set(name, value);
    } else {
      values.add(value);
    }
  }

  /// Sets a header. The header named [name] will have all its values
  /// cleared before the value [value] is added as its value.
  void set(String name, dynamic value) {
    name = name.trim().toLowerCase();
    if (value is List) {
      _map[name] = value.map<String>((e) => e.toString()).toList();
    } else {
      _map[name] = [value.trim()];
    }
  }

  /// Removes a specific value for a header name.
  void remove(String name, String value) {
    var values = this[name];
    if (values == null) return;
    values.removeWhere((v) => v == value);
  }

  /// Removes all values for the specified header name.
  void removeAll(String name) {
    _map.remove(name);
  }

  void clear() {
    _map.clear();
  }

  /// Enumerates the headers, applying the function [f] to each
  /// header. The header name passed in [:name:] will be all lower
  /// case.
  void forEach(HeaderForEachCallback f) {
    _map.keys.forEach((key) => f(key, this[key]!));
  }

  @override
  String toString() {
    var stringBuffer = StringBuffer();
    _map.forEach((key, value) {
      value.forEach((e) => stringBuffer.writeln('$key: $e'));
    });
    return stringBuffer.toString();
  }
}
