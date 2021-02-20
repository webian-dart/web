import 'dart:async';

import 'package:test/test.dart';
import 'package:web/web.dart';

import 'mock_adapter.dart';

class MyInterceptor extends Interceptor {
  int requestCount = 0;

  @override
  Future onRequest(RequestOptions options) {
    requestCount++;
    return super.onRequest(options);
  }
}

void main() {
  group('#test Request Interceptor', () {
    Web web;

    test('#test request interceptor', () async {
      web = Web();
      web.options.baseUrl = MockAdapter.mockBase;
      web.httpClientAdapter = MockAdapter();
      web.interceptors
          .add(InterceptorsWrapper(onRequest: (RequestOptions options) async {
        switch (options.path) {
          case '/fakepath1':
            return web.resolve('fake data');
          case '/fakepath2':
            return web.get('/test');
          case '/fakepath3':
            return web.reject(
                'test error'); //you can also return a HttpError directly.
          case '/fakepath4':
            return Fault(
                error:
                    'test error'); // Here is equivalent to call web.reject('test error')
          case '/test?tag=1':
            {
              final response = await web.get('/token');
              options.headers['token'] = response.data['data']['token'];
              return options;
            }
          default:
            return options; //continue
        }
      }));

      var response = await web.get('/fakepath1');
      expect(response.data, 'fake data');
      response = await web.get('/fakepath2');
      expect(response.data['errCode'], 0);

      expect(web.get('/fakepath3').catchError((e) => throw e.message),
          throwsA(equals('test error')));
      expect(web.get('/fakepath4').catchError((e) => throw e.message),
          throwsA(equals('test error')));

      response = await web.get('/test');
      expect(response.data['errCode'], 0);
      response = await web.get('/test?tag=1');
      expect(response.data['errCode'], 0);
    });
  });

  test('#test Response Interceptor', () async {
    Web web;

    const URL_NOT_FIND = '/404/';
    const URL_NOT_FIND_1 = URL_NOT_FIND + '1';
    const URL_NOT_FIND_2 = URL_NOT_FIND + '2';
    const URL_NOT_FIND_3 = URL_NOT_FIND + '3';

    web = Web();
    web.httpClientAdapter = MockAdapter();
    web.options.baseUrl = MockAdapter.mockBase;

    web.interceptors.add(InterceptorsWrapper(
      onResponse: (Response response) {
        return response.data['data'];
      },
      onError: (e) {
        if (e.response != null) {
          switch (e.response!.request?.path) {
            case URL_NOT_FIND:
              return e;
            case URL_NOT_FIND_1:
              return web.resolve(
                  'fake data'); // you can also return a HttpError directly.
            case URL_NOT_FIND_2:
              return Response(data: 'fake data');
            case URL_NOT_FIND_3:
              return 'custom error info [${e.response!.statusCode}]';
          }
        }
        return e;
      },
    ));
    var response = await web.get('/test');
    expect(response.data['path'], '/test');
    expect(web.get(URL_NOT_FIND).catchError((e) => throw e.response.statusCode),
        throwsA(equals(404)));
    response = await web.get(URL_NOT_FIND + '1');
    expect(response.data, 'fake data');
    response = await web.get(URL_NOT_FIND + '2');
    expect(response.data, 'fake data');
    expect(web.get(URL_NOT_FIND + '3').catchError((e) => throw e.message),
        throwsA(equals('custom error info [404]')));
  });

  group('Interceptor request lock', () {
    test('test', () async {
      String? csrfToken;
      final web = Web();
      var tokenRequestCounts = 0;
      // Web instance to request token
      var tokenWeb = Web();
      web.options.baseUrl = tokenWeb.options.baseUrl = MockAdapter.mockBase;
      web.httpClientAdapter = tokenWeb.httpClientAdapter = MockAdapter();
      var myInter = MyInterceptor();
      web.interceptors.add(myInter);
      web.interceptors
          .add(InterceptorsWrapper(onRequest: (RequestOptions options) {
        if (csrfToken == null) {
          web.lock();
          tokenRequestCounts++;
          return tokenWeb.get('/token').then((d) {
            options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
            return options;
          }).whenComplete(() => web.unlock()); // unlock the Web
        } else {
          options.headers['csrfToken'] = csrfToken;
          return options;
        }
      }));

      var result = 0;
      void _onResult(d) {
        if (tokenRequestCounts > 0) ++result;
      }

      await Future.wait([
        web.get('/test?tag=1').then(_onResult),
        web.get('/test?tag=2').then(_onResult),
        web.get('/test?tag=3').then(_onResult)
      ]);
      expect(tokenRequestCounts, 1);
      expect(result, 3);
      assert(myInter.requestCount > 0);
      web.interceptors[0] = myInter;
      web.interceptors.clear();
      assert(web.interceptors.isEmpty == true);
    });
  });

  group('Interceptor error lock', () {
    test('test', () async {
      String? csrfToken;
      final web = Web();
      var tokenRequestCounts = 0;
      // Web instance to request token
      final tokenWeb = Web();
      web.options.baseUrl = tokenWeb.options.baseUrl = MockAdapter.mockBase;
      web.httpClientAdapter = tokenWeb.httpClientAdapter = MockAdapter();
      web.interceptors.add(InterceptorsWrapper(onRequest: (opt) {
        opt.headers['csrfToken'] = csrfToken;
      }, onError: (Fault error) {
        // Assume 401 stands for token expired
        if (error.response?.statusCode == 401) {
          final options = error.response!.request!;
          // If the token has been updated, repeat directly.
          if (csrfToken != options.headers['csrfToken']) {
            options.headers['csrfToken'] = csrfToken;
            //repeat
            return web.request(options.path, options: options);
          }
          // update token and repeat
          // Lock to block the incoming request until the token updated
          web.lock();
          web.interceptors.responseLock.lock();
          web.interceptors.errorLock.lock();
          tokenRequestCounts++;
          return tokenWeb.get('/token').then((d) {
            //update csrfToken
            options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
          }).whenComplete(() {
            web.unlock();
            web.interceptors.responseLock.unlock();
            web.interceptors.errorLock.unlock();
          }).then((e) {
            //repeat
            return web.request(options.path, options: options);
          });
        }
        return error;
      }));

      var result = 0;
      void _onResult(d) {
        if (tokenRequestCounts > 0) ++result;
      }

      await Future.wait([
        web.get('/test-auth?tag=1').then(_onResult),
        web.get('/test-auth?tag=2').then(_onResult),
        web.get('/test-auth?tag=3').then(_onResult)
      ]);
      expect(tokenRequestCounts, 1);
      expect(result, 3);
    });
  });
}
