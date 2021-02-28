import 'dart:async';

import 'package:web/src/faults/faults_factory.dart';
import 'package:web/src/requests/request.dart';
import 'package:web/src/responses/response_factory.dart';

import '../../web.dart';
import '../options/request_options.dart';
import '../requests/cancel_token.dart';
import '../responses/response.dart';
import 'interceptors.dart';
import 'lock.dart';

class InterceptorsWrapper {
  final Interceptors interceptors;
  final CancelToken? cancelToken;
  final RequestOptions? requestOptions;

  InterceptorsWrapper(
      {required this.cancelToken,
      required this.interceptors,
      required this.requestOptions});

  // Convert the request interceptor to a functional callback in which
  // we can handle the return value of interceptor callback.
  FutureOr<dynamic> Function(dynamic) wrapForRequest(interceptor) {
    return (data) async {
      final isReq = data is RequestOptions;
      final lock = interceptors.requestLock;
      final isError = Request.isErrorOrException(data);
      if (isError || isReq) {
        return Request.listenCancelForAsyncTask(
          cancelToken,
          Future(() {
            return checkIfNeedEnqueue(lock, () {
              if (isReq) {
                return interceptor(data).then((e) => e ?? data);
              } else {
                throw FaultsFactory.build(data, requestOptions);
              }
            });
          }),
        );
      } else {
        // skip request interceptor
        return ResponseFactory.build(data, requestOptions);
      }
    };
  }

  // Convert the request interceptor to a functional callback in which
  // we can handle the return value of interceptor callback.
  FutureOr<dynamic> Function(dynamic) wrapForResponse(interceptor) {
    return (data) async {
      final isResp = data is Response;
      final lock = interceptors.responseLock;
      final isError = Request.isErrorOrException(data);
      if (isResp || isError) {
        return Request.listenCancelForAsyncTask(
          cancelToken,
          Future(() {
            return checkIfNeedEnqueue(lock, () {
              if (isError) {
                throw FaultsFactory.build(data, requestOptions);
              } else {
                if (isResp) {
                  data.request = data.request ?? requestOptions;
                } else {
                  data = ResponseFactory.build(data, requestOptions);
                }
                return interceptor(data).then((e) => e ?? data);
              }
            });
          }),
        );
      } else {
        // skip request interceptor
        return ResponseFactory.build(data, requestOptions);
      }
    };
  }

  // Convert the error interceptor to a functional callback in which
  // we can handle the return value of interceptor callback.
  FutureOr<dynamic> Function(dynamic) makeOnErrorHandler(errInterceptor) {
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
