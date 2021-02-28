import 'dart:collection';

import 'interceptor.dart';
import 'lock.dart';

class Interceptors extends ListMixin<Interceptor> {
  final _list = <Interceptor>[];
  final Lock _requestLock = Lock();
  final Lock _responseLock = Lock();
  final Lock _errorLock = Lock();

  Lock get requestLock => _requestLock;

  Lock get responseLock => _responseLock;

  Lock get errorLock => _errorLock;

  @override
  int length = 0;

  @override
  Interceptor operator [](int index) {
    return _list[index];
  }

  @override
  void operator []=(int index, value) {
    if (_list.length == index) {
      _list.add(value);
    } else {
      _list[index] = value;
    }
  }
}
