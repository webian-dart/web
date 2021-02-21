import 'dart:async';

import 'package:web/src/faults/faults_factory.dart';
import 'package:web/src/requests/request.dart';
import 'package:web/src/responses/response_factory.dart';

import '../../web.dart';
import '../options/request_options.dart';
import '../requests/cancel_token.dart';
import '../responses/response.dart';

class InterceptorWrapper {
  final Interceptors interceptors;
  final CancelToken? cancelToken;
  final RequestOptions? requestOptions;

  InterceptorWrapper(
      {required this.cancelToken,
      required this.interceptors,
      required this.requestOptions});

  // Convert the request/response interceptor to a functional callback in which
  // we can handle the return value of interceptor callback.
  FutureOr<dynamic> Function(dynamic) handle(interceptor, bool request) {
    return (data) async {
      var type = request ? (data is RequestOptions) : (data is Response);
      var lock = request ? interceptors.requestLock : interceptors.responseLock;
      if (Request.isErrorOrException(data) || type) {
        return Request.listenCancelForAsyncTask(
          cancelToken,
          Future(() {
            return checkIfNeedEnqueue(lock, () {
              if (type) {
                if (!request) data.request = data.request ?? requestOptions;
                return interceptor(data).then((e) => e ?? data);
              } else {
                throw FaultsFactory.build(data, requestOptions);
              }
            });
          }),
        );
      } else {
        return ResponseFactory.build(data, requestOptions);
      }
    };
  }

  // Convert the error interceptor to a functional callback in which
  // we can handle the return value of interceptor callback.
  FutureOr<dynamic> Function(dynamic) handleError(errInterceptor) {
    return (err) {
      return checkIfNeedEnqueue(interceptors.errorLock, () {
        if (err is! Response) {
          return errInterceptor(FaultsFactory.build(err, requestOptions))
              .then((e) {
            if (e is! Response) {
              throw FaultsFactory.build(e ?? err, requestOptions);
            }
            return e;
          });
        }
        // err is a Response instance
        return err;
      });
    };
  }

  FutureOr checkIfNeedEnqueue(Lock lock, EnqueueCallback callback) {
    if (lock.locked) {
      return lock.enqueue(callback);
    } else {
      return callback();
    }
  }
}
