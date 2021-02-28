import 'dart:async';

import '../faults/fault.dart';
import '../options/request_options.dart';
import '../responses/response.dart';

typedef OnRequest = dynamic Function(RequestOptions options);
typedef OnFault = dynamic Function(Fault e);
typedef OnResponse = dynamic Function(Response e);

///  Web instance may have interceptor(s) by which you can intercept
///  requests or responses before they are handled by `then` or `catchError`.
class Interceptor {
  /// The callback will be executed before the request is initiated.
  ///
  /// If you want to resolve the request with some custom data，
  /// you can return a [Response] object or return [Web.resolve].
  /// If you want to reject the request with a error message,
  /// you can return a [Fault] object or return [Web.reject] .
  /// If you want to continue the request, return the [Options] object.
  /// ```dart
  ///  Future onRequest(RequestOptions options) => Web.resolve('fake data');
  ///  ...
  ///  print(response.data) // 'fake data';
  /// ```
  Future onRequest(RequestOptions options) async => options;

  /// The callback will be executed on success.
  ///
  /// If you want to reject the request with a error message,
  /// you can return a [Fault] object or return [Web.reject] .
  /// If you want to continue the request, return the [Response] object.
  Future onResponse(Response response) async => response;

  /// The callback will be executed on fault.
  ///
  /// If you want to resolve the request with some custom data，
  /// you can return a [Response] object or return [Web.resolve].
  /// If you want to continue the request, return the [Fault] object.
  Future onFault(Fault fault) async => fault;
}
