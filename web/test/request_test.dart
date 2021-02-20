// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:Web/Web.dart';
import 'package:test/test.dart';

import 'utils.dart';

@TestOn('vm')
void main() {
  setUp(startServer);

  tearDown(stopServer);

  group('#test requests', () {
    late Web Web;
    setUp(() {
      Web = Web();
      Web.options
        ..baseUrl = serverUrl.toString()
        ..connectTimeout = 1000
        ..receiveTimeout = 5000
        ..headers = {'User-Agent': 'dartisan'};
      Web.interceptors.add(LogInterceptor(
        responseBody: true,
        requestBody: true,
        logPrint: (log) => {
          // ignore log
        },
      ));
    });
    test('#test restful APIs', () async {
      Response response;

      // test get
      response = await Web.get(
        '/test',
        queryParameters: {'id': '12', 'name': 'wendu'},
      );
      expect(response.statusCode, 200);
      expect(response.isRedirect, false);
      expect(response.data['query'], equals('id=12&name=wendu'));
      expect(response.headers.value('single'), equals('value'));

      const map = {'content': 'I am playload'};

      // test post
      response = await Web.post('/test', data: map);
      expect(response.data['method'], 'POST');
      expect(response.data['body'], jsonEncode(map));

      // test put
      response = await Web.put('/test', data: map);
      expect(response.data['method'], 'PUT');
      expect(response.data['body'], jsonEncode(map));

      // test patch
      response = await Web.patch('/test', data: map);
      expect(response.data['method'], 'PATCH');
      expect(response.data['body'], jsonEncode(map));

      // test head
      response = await Web.delete('/test', data: map);
      expect(response.data['method'], 'DELETE');
      expect(response.data['path'], '/test');

      // error test
      expect(Web.get('/error').catchError((e) => throw e.response.statusCode),
          throwsA(equals(400)));

      // redirect test
      response = await Web.get(
        '/redirect',
        onReceiveProgress: (received, total) {
          // ignore progress
        },
      );
      assert(response.isRedirect == true);
      assert(response.redirects.length == 1);
      var ri = response.redirects.first;
      assert(ri.statusCode == 302);
      assert(ri.method == 'GET');
    });

    test('#test request with URI', () async {
      Response response;

      // test get
      response = await Web.getUri(
        Uri(path: '/test', queryParameters: {'id': '12', 'name': 'wendu'}),
      );
      expect(response.statusCode, 200);
      expect(response.isRedirect, false);
      expect(response.data['query'], equals('id=12&name=wendu'));
      expect(response.headers.value('single'), equals('value'));

      const map = {'content': 'I am playload'};

      // test post
      response = await Web.postUri(Uri(path: '/test'), data: map);
      expect(response.data['method'], 'POST');
      expect(response.data['body'], jsonEncode(map));

      // test put
      response = await Web.putUri(Uri(path: '/test'), data: map);
      expect(response.data['method'], 'PUT');
      expect(response.data['body'], jsonEncode(map));

      // test patch
      response = await Web.patchUri(Uri(path: '/test'), data: map);
      expect(response.data['method'], 'PATCH');
      expect(response.data['body'], jsonEncode(map));

      // test head
      response = await Web.deleteUri(Uri(path: '/test'), data: map);
      expect(response.data['method'], 'DELETE');
      expect(response.data['path'], '/test');
    });

    test('#test redirect', () async {
      Response response;
      response = await Web.get('/redirect');
      assert(response.isRedirect == true);
      assert(response.redirects.length == 1);
      var ri = response.redirects.first;
      assert(ri.statusCode == 302);
      assert(ri.method == 'GET');
      assert(ri.location.path == '/');
    });

    test('#test generic parameters', () async {
      Response response;

      // default is "Map"
      response = await Web.get('/test');
      assert(response.data is Map);

      // get response as `string`
      response = await Web.get<String>('/test');
      assert(response.data is String);

      // get response as `Map`
      response = await Web.get<Map>('/test');
      assert(response.data is Map);

      // get response as `List`
      response = await Web.get<List>('/list');
      assert(response.data is List);
      expect(response.data[0], 1);
    });
  });
}
