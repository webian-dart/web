import 'dart:async';

import 'package:web/web.dart';

void main() async {
  final web = Web();
  //  web instance to request token
  final tokenWeb = Web();
  String? csrfToken;
  web.options.baseUrl = 'http://www.dtworkroom.com/doris/1/2.0.0/';
  tokenWeb.options = web.options;
  web.interceptors.add(RequestInterceptor((RequestOptions options) {
    print('send request：path:${options.path}，baseURL:${options.baseUrl}');
    if (csrfToken == null) {
      print('no token，request token firstly...');
      web.lock();
      //print(web.interceptors.requestLock.locked);
      return tokenWeb.get('/token').then((d) {
        options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
        print('request token succeed, value: ' + d.data['data']['token']);
        print(
            'continue to perform request：path:${options.path}，baseURL:${options.path}');
        return options;
      }).whenComplete(() => web.unlock()); // unlock the web
    } else {
      options.headers['csrfToken'] = csrfToken;
      return options;
    }
  }));
  web.interceptors.add(FaultInterceptor((Fault error) {
    //print(error);
    // Assume 401 stands for token expired
    if (error.response?.statusCode == 401) {
      final options = error.response!.request;
      // If the token has been updated, repeat directly.
      if (csrfToken != options?.headers['csrfToken']) {
        options?.headers['csrfToken'] = csrfToken;
        //repeat
        return web.request(options?.path ?? '', options: options);
      }
      // update token and repeat
      // Lock to block the incoming request until the token updated
      web.lock();
      web.interceptors.responseLock.lock();
      web.interceptors.errorLock.lock();
      return tokenWeb.get('/token').then((d) {
        //update csrfToken
        options?.headers['csrfToken'] = csrfToken = d.data['data']['token'];
      }).whenComplete(() {
        web.unlock();
        web.interceptors.responseLock.unlock();
        web.interceptors.errorLock.unlock();
      }).then((e) {
        //repeat
        return web.request(options?.path ?? '', options: options);
      });
    }
    return error;
  }));

  void _onResult(d) {
    print('request ok!');
  }

  await Future.wait([
    web.get('/test?tag=1').then(_onResult),
    web.get('/test?tag=2').then(_onResult),
    web.get('/test?tag=3').then(_onResult)
  ]);
}
