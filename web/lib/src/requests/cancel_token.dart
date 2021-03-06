import 'dart:async';

import '../faults/fault.dart';

/// You can cancel a request by using a cancel token.
/// One token can be shared between different requests.
/// When a token's [cancel] method is invoked, all requests
/// with with the same token will be cancelled.
class CancelToken {
  CancelToken() {
    _completer = Completer();
  }

  /// Whether is throw by [cancel]
  static bool isCancel(Fault e) {
    return e.type == FaultType.CANCEL;
  }

  /// If request have been canceled, save the cancel Error.
  Fault? _cancelError;

  /// If request have been canceled, save the cancel Error.
  Fault? get cancelError => _cancelError;

  late Completer _completer;

  /// whether cancelled
  bool get isCancelled => _cancelError != null;

  /// When cancelled, this future will be resolved.
  Future<void> get whenCancel => _completer.future;

  /// Cancel the request
  void cancel([dynamic reason]) {
    _cancelError = Fault(type: FaultType.CANCEL, error: reason);
    _completer.complete();
  }
}
