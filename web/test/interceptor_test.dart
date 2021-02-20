import 'dart:async';

import 'package:Web/Web.dart';
import 'package:test/test.dart';

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
    Web Web;

    test('#test request interceptor', () async {
      Web = Web();
      Web.options.baseUrl = MockAdapter.mockBase;
      Web.httpClientAdapter = MockAdapter();
      Web.interceptors
          .add(InterceptorsWrapper(onRequest: (RequestOptions options) async {
        switch (options.path) {
          case '/fakepath1':
            return Web.resolve('fake data');
          case '/fakepath2':
            return Web.get('/test');
          case '/fakepath3':
            return Web.reject(
                'test error'); //you can also return a HttpError directly.
          case '/fakepath4':
            return WebError(
                error:
                    'test error'); // Here is equivalent to call Web.reject('test error')
          case '/test?tag=1':
            {
              final response = await Web.get('/token');
              options.headers['token'] = response.data['data']['token'];
              return options;
            }
          default:
            return options; //continue
        }
      }));

      var response = await Web.get('/fakepath1');
      expect(response.data, 'fake data');
      response = await Web.get('/fakepath2');
      expect(response.data['errCode'], 0);

      expect(Web.get('/fakepath3').catchError((e) => throw e.message),
          throwsA(equals('test error')));
      expect(Web.get('/fakepath4').catchError((e) => throw e.message),
          throwsA(equals('test error')));

      response = await Web.get('/test');
      expect(response.data['errCode'], 0);
      response = await Web.get('/test?tag=1');
      expect(response.data['errCode'], 0);
    });
  });

  test('#test Response Interceptor', () async {
    Web Web;

    const URL_NOT_FIND = '/404/';
    const URL_NOT_FIND_1 = URL_NOT_FIND + '1';
    const URL_NOT_FIND_2 = URL_NOT_FIND + '2';
    const URL_NOT_FIND_3 = URL_NOT_FIND + '3';

    Web = Web();
    Web.httpClientAdapter = MockAdapter();
    Web.options.baseUrl = MockAdapter.mockBase;

    Web.interceptors.add(InterceptorsWrapper(
      onResponse: (Response response) {
        return response.data['data'];
      },
      onError: (e) {
        if (e.response != null) {
          switch (e.response!.request?.path) {
            case URL_NOT_FIND:
              return e;
            case URL_NOT_FIND_1:
              return Web.resolve(
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
    var response = await Web.get('/test');
    expect(response.data['path'], '/test');
    expect(Web.get(URL_NOT_FIND).catchError((e) => throw e.response.statusCode),
        throwsA(equals(404)));
    response = await Web.get(URL_NOT_FIND + '1');
    expect(response.data, 'fake data');
    response = await Web.get(URL_NOT_FIND + '2');
    expect(response.data, 'fake data');
    expect(Web.get(URL_NOT_FIND + '3').catchError((e) => throw e.message),
        throwsA(equals('custom error info [404]')));
  });

  group('Interceptor request lock', () {
    test('test', () async {
      String? csrfToken;
      final Web = Web();
      var tokenRequestCounts = 0;
      // Web instance to request token
      final tokenWeb = Web();
      Web.options.baseUrl = tokenWeb.options.baseUrl = MockAdapter.mockBase;
      Web.httpClientAdapter = tokenWeb.httpClientAdapter = MockAdapter();
      var myInter = MyInterceptor();
      Web.interceptors.add(myInter);
      Web.interceptors
          .add(InterceptorsWrapper(onRequest: (RequestOptions options) {
        if (csrfToken == null) {
          Web.lock();
          tokenRequestCounts++;
          return tokenWeb.get('/token').then((d) {
            options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
            return options;
          }).whenComplete(() => Web.unlock()); // unlock the Web
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
        Web.get('/test?tag=1').then(_onResult),
        Web.get('/test?tag=2').then(_onResult),
        Web.get('/test?tag=3').then(_onResult)
      ]);
      expect(tokenRequestCounts, 1);
      expect(result, 3);
      assert(myInter.requestCount > 0);
      Web.interceptors[0] = myInter;
      Web.interceptors.clear();
      assert(Web.interceptors.isEmpty == true);
    });
  });

  group('Interceptor error lock', () {
    test('test', () async {
      String? csrfToken;
      final Web = Web();
      var tokenRequestCounts = 0;
      // Web instance to request token
      final tokenWeb = Web();
      Web.options.baseUrl = tokenWeb.options.baseUrl = MockAdapter.mockBase;
      Web.httpClientAdapter = tokenWeb.httpClientAdapter = MockAdapter();
      Web.interceptors.add(InterceptorsWrapper(onRequest: (opt) {
        opt.headers['csrfToken'] = csrfToken;
      }, onError: (WebError error) {
        // Assume 401 stands for token expired
        if (error.response?.statusCode == 401) {
          final options = error.response!.request!;
          // If the token has been updated, repeat directly.
          if (csrfToken != options.headers['csrfToken']) {
            options.headers['csrfToken'] = csrfToken;
            //repeat
            return Web.request(options.path, options: options);
          }
          // update token and repeat
          // Lock to block the incoming request until the token updated
          Web.lock();
          Web.interceptors.responseLock.lock();
          Web.interceptors.errorLock.lock();
          tokenRequestCounts++;
          return tokenWeb.get('/token').then((d) {
            //update csrfToken
            options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
          }).whenComplete(() {
            Web.unlock();
            Web.interceptors.responseLock.unlock();
            Web.interceptors.errorLock.unlock();
          }).then((e) {
            //repeat
            return Web.request(options.path, options: options);
          });
        }
        return error;
      }));

      var result = 0;
      void _onResult(d) {
        if (tokenRequestCounts > 0) ++result;
      }

      await Future.wait([
        Web.get('/test-auth?tag=1').then(_onResult),
        Web.get('/test-auth?tag=2').then(_onResult),
        Web.get('/test-auth?tag=3').then(_onResult)
      ]);
      expect(tokenRequestCounts, 1);
      expect(result, 3);
    });
  });
}
