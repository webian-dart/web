import 'package:web/src/faults/fault.dart';

import 'interceptor.dart';

class FaultInterceptor extends Interceptor {
  final OnFault _onFaultHandler;

  FaultInterceptor(OnFault handler) : _onFaultHandler = handler;

  @override
  Future onFault(Fault fault) async => _onFaultHandler(fault);
}
