import 'package:web/src/options/request_options.dart';

import 'fault.dart';

class FaultsFactory {
  static Fault build(err, [RequestOptions? requestOptions]) {
    Fault fault;
    if (err is Fault) {
      fault = err;
    } else {
      fault = Fault(error: err);
    }
    fault.request = fault.request ?? requestOptions;
    return fault;
  }
}
