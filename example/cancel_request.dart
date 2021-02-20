import 'dart:async';

import 'package:web/web.dart';

main() async {
  var web = Web();
  web.interceptors.add(LogInterceptor());
  // Token can be shared with different requests.
  final token = CancelToken();
  // In one minute, we cancel!
  Timer(Duration(milliseconds: 500), () {
    token.cancel("cancelled");
  });

  // The follow three requests with the same token.
  var url1 = "https://www.google.com";
  var url2 = "https://www.facebook.com";
  var url3 = "https://www.google.com";

  await Future.wait([
    web
        .get(url1, cancelToken: token)
        .then((response) => print('${response.request!.path}: succeed!'))
        .catchError(
      (e) {
        if (CancelToken.isCancel(e)) {
          print('$url1: $e');
        }
      },
    ),
    web
        .get(url2, cancelToken: token)
        .then((response) => print('${response.request!.path}: succeed!'))
        .catchError((e) {
      if (CancelToken.isCancel(e)) {
        print('$url2: $e');
      }
    }),
    web
        .get(url3, cancelToken: token)
        .then((response) => print('${response.request!.path}: succeed!'))
        .catchError((e) {
      if (CancelToken.isCancel(e)) {
        print('$url3: $e');
      }
      print(e);
    })
  ]);
}
