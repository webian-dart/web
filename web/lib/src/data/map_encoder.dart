typedef WebEncodeHandler = Function(String key, Object? value);

class MapEncoder {
  final Map data;
  final WebEncodeHandler webEncoder;
  late final String _leftBracket;
  late final String _rightBracket;
  late final Function(String) _encodeComponent;
  bool _isFirstEncodingPass = false;
  String _cachedEncoded = '';
  final StringBuffer _encodedBuffer = StringBuffer('');

  MapEncoder(
      {required this.data, required this.webEncoder, bool encode = true}) {
    _leftBracket = encode ? '%5B' : '[';
    _rightBracket = encode ? '%5D' : ']';
    _encodeComponent = encode ? Uri.encodeQueryComponent : (e) => e;
  }

  String encode() {
    if (_cachedEncoded.isNotEmpty) return _cachedEncoded;
    _isFirstEncodingPass = true;
    _encode(data, '');
    _cachedEncoded = _encodedBuffer.toString();
    return _cachedEncoded;
  }

  void _encode(dynamic dataToEncode, String path) {
    if (dataToEncode is List) {
      _listEncode(dataToEncode, path);
    } else if (dataToEncode is Map) {
      _mapEncode(dataToEncode, path);
    } else {
      _nonMapOrListEncode(dataToEncode, path);
    }
  }

  void _listEncode(dynamic dataToEncode, String path) {
    for (var i = 0; i < dataToEncode.length; i++) {
      _encode(
        dataToEncode[i],
        '$path$_leftBracket${(dataToEncode[i] is Map || dataToEncode[i] is List) ? i : ''}$_rightBracket',
      );
    }
  }

  void _mapEncode(dynamic dataToEncode, String path) {
    dataToEncode.forEach((k, v) {
      if (path == '') {
        _encode(v, '${_encodeComponent(k)}');
      } else {
        _encode(v, '$path$_leftBracket${_encodeComponent(k)}$_rightBracket');
      }
    });
  }

  void _nonMapOrListEncode(dynamic dataToEncode, String path) {
    final str = webEncoder(path, dataToEncode);
    final isNotEmpty = str != null && str.trim().isNotEmpty;
    if (!_isFirstEncodingPass && isNotEmpty) {
      _encodedBuffer.write('&');
    }
    _isFirstEncodingPass = false;
    if (isNotEmpty) {
      _encodedBuffer.write(str);
    }
  }
}
